from ssl import SSLError

import jwt
from flask import Blueprint, Response, request, jsonify
import logging
import json
import requests
import os
from urllib3.connection import HTTPConnection
from OpenSSL import SSL as ssl

from flaskAppServer.authenticate import token_required
from cryptography.x509 import load_pem_x509_certificate
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from flaskAppServer.patch import patch_requests
from flaskAppServer.apperrhandler import AppException
from flaskAppServer.template import JsonTemplates

VAULT_ENDPOINT = os.environ['VAULT_URI'] + '/v1/pki_int/issue/client_certs'
VAULT_AUTH_ENDPOINT = os.environ['VAULT_URI'] + '/v1/auth/jwt/login'
SAP_ENDPOINT = os.environ['SAP_ENDPOINT']
METADATA = os.environ['METADATA_URI']
CERT_TEMPLATE = os.environ['CERT_TEMPLATE']

bp = Blueprint('proxy', __name__, url_prefix='/')

logger = logging.getLogger(__name__)


@bp.route('/health', methods=['GET'])
def health():
    return "OK", 200


@bp.route('/gencert', methods=['GET'])
@token_required  # Verify token decorator
def gencert(access_token, current_user):
    logger.info("Generating short lived cert for user %s", current_user['name'])
    logger.debug("Generating short lived cert for user %s", current_user)

    (cert, pvk) = get_cert(access_token, current_user)
    x509_cert = load_pem_x509_certificate(cert.encode(), default_backend())

    logger.debug("X.509 Public Key Contents - refer to web output. "
                 "The private key is not generated nor stored.")

    return x509_cert.public_bytes(serialization.Encoding.PEM), 200


@bp.route('/<path:path>', methods=['GET', 'POST', 'DELETE', 'PUT'])
@token_required  # Verify token decorator
def proxy(access_token, current_user, path):
    endpoint = SAP_ENDPOINT

    csrf_path = METADATA
    if path.startswith("sap/opu/odata/sap"):
        elements = path.split('/')[0:5]
        elements.append("$metadata")
        csrf_path = "/".join(elements)

    logger.info("Proxying call to SAP Backend - %s", endpoint)

    logger.info("Getting short lived Certificate from SOCM Vault for proxying purposes")
    try:
        (cert, pvk) = get_cert(access_token, current_user)
    except Exception as ex:
        logger.error("Internal Vault Error while creating user certificate %s", ex)
        raise AppException(ex, status_code=511, message="Internal Vault Error while creating user certificate")

    x509_cert = load_pem_x509_certificate(cert.encode(), default_backend())
    cert_key = serialization.load_pem_private_key(pvk.encode(), None, default_backend())

    logger.info("Successfully gotten certificate for user %s", current_user['name'])

    logger.debug("Patching URL requests")
    patch_requests()
    logger.debug("Patching done")

    excluded_proxy_headers = ['authorization',
                              'host',
                              'agent',
                              'user-agent',
                              'postman-token',
                              'connection',
                              'cookie',
                              'x-csrf-token',
                              'content-length']
    excluded_resp_headers = ['content-encoding',
                             'content-length',
                             'transfer-encoding',
                             'connection',
                             'x-csrf-token',
                             'set-cookie']
    resp = None

    headers = {
        key: value for (key, value) in request.headers.items()
        if key.lower() not in excluded_proxy_headers
    }

    logger.debug("Final prepared headers %s after removing the headers %s", headers, excluded_proxy_headers)

    if request.method in ['PUT', 'POST', 'DELETE']:
        logger.info("Request Method is %s and thus getting CSRF Token", request.method)

        try:
            head_repsonse = requests.head(
                url=endpoint + csrf_path,
                allow_redirects=False,
                cert=(x509_cert, cert_key),
                headers={'x-csrf-token': 'fetch'},
                verify=False
            )
        except Exception as ex1:
            logger.error("Vault CA not trusted in SAP %s", ex1)
            logger.debug(ex1)
            raise AppException(Exception("SAP Connection Error. See logs for details"), status_code=508)

        if head_repsonse.status_code != 200:
            logger.info("Invalid URL configured. Either wrong URL or wrong MetadataURI %s%s", endpoint, METADATA)
            raise AppException(Exception("Wrong Metadata URL configured. Please re-configure"), status_code=501)

        if 'x-csrf-token' in head_repsonse.headers:
            logger.info("Received CSRF Token")
            logger.debug("Received CSRF Token & Cookie in header %s", head_repsonse.headers)

            csrftoken = head_repsonse.headers['x-csrf-token']
            headers.update({'x-csrf-token': csrftoken})
        else:
            logger.info("Return Headers doesnt contain CSRF token. Interrupting further transmission")
            logger.debug("Typically happens when user mapping cannot be done with X.509 certificates. "
                         "Run a /getcert to evaluate the cert structure")
            logger.debug("Header as received %s", head_repsonse.headers)
            raise AppException(
                Exception('User incorrectly mapped or doesnt exist in SAP. No valid fetching CSRF token returned.'),
                status_code=403)

        logger.info("Making final write call with X-CSRF-Token and Session Cookie %s ",
                    request.url.replace(request.host_url, endpoint))
        try:
            resp = requests.request(
                method=request.method,
                url=request.url.replace(request.host_url, endpoint),
                data=request.get_data(),
                cookies=head_repsonse.cookies,
                headers=headers,
                allow_redirects=False,
                cert=(x509_cert, cert_key),
                verify=False
            )
        except Exception as ex1:
            logger.error("Connection Error %s", ex1)
            logger.debug(ex1)
            raise AppException(Exception("SAP Connection Error. See logs for details"), status_code=508)


    else:
        logger.info("Request Method is %s thus no need of getting CSRF Token", request.method)
        logger.info("Making final write call without X-CSRF-Token %s ",
                    request.url.replace(request.host_url, endpoint))

        try:
            resp = requests.request(
                method=request.method,
                url=request.url.replace(request.host_url, endpoint),
                headers=headers,
                data=request.get_data(),
                allow_redirects=False,
                cert=(x509_cert, cert_key),
                verify=False
            )
        except Exception as ex1:
            logger.error("Connection Error %s", ex1)
            logger.debug(ex1)
            raise AppException(Exception("SAP Connection Error. See logs for details"), status_code=508)

    logger.info("Proxy Call Completed")
    logger.debug("Call to %s completed", request.url.replace(request.host_url, endpoint))

    logger.info("Removing secret elements of header. Cookies, Tokens, returning only data")
    headers = {
        (name, value) for (name, value) in resp.raw.headers.items()
        if name.lower() not in excluded_resp_headers
    }
    logger.info("Final Headers in Response %s", headers)
    response = Response(resp.content, resp.status_code, headers)
    return response


def get_csrf_header_and_cookies():
    return None



def get_cert(access_token, user):
    logger.info("Getting certificate from SOCM Vault upn %s", user['name'])
    auth_payload = json.dumps({
        "role": "jwt_client_cert",
        "jwt": access_token
    })
    auth_headers = {
        'Content-Type': 'application/json'
    }
    auth_response = requests.request("POST", VAULT_AUTH_ENDPOINT, headers=auth_headers, data=auth_payload)
    if auth_response.status_code != 200:
        logger.error("Error logging into Vault using JWT")
        logger.debug("Vault Error Code %d %s", auth_response.status_code, auth_response.json())
        raise Exception(auth_response.json())

    logger.info("Successfully logged into Vault using JWT")

    vault_token = auth_response.json()['auth']['client_token']

    cert_template = JsonTemplates()
    cert_json = cert_template.load(CERT_TEMPLATE)
    logger.debug("Template for certificate %s", cert_json)

    if cert_json[0]: # This is true
        logger.info("Generating payload for certificate from certificate template")
        cert_json_payload = cert_template.generate(user)
    else:
        logger.error("Invalid Certificate Template")
        logger.info("Template for certificate %s", cert_json)
        raise Exception("Invalid Certificate Template")

    if cert_json_payload[0]: #This is true
        cert_payload = cert_json_payload[1]
    else:
        logger.error("Error generating template %s", cert_json_payload[1])
        raise Exception("Error generating Template")

    logger.debug("Payload for Vault %s", cert_payload)

    headers = {
        'X-Vault-Token': vault_token,
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", VAULT_ENDPOINT, headers=headers, data=json.dumps(cert_payload))

    if response.status_code != 200:
        logger.error("Error getting Certificate")
        logger.debug("Vault Error Code %d %s", response.status_code, response.json())
        raise Exception(response.json())

    cert = response.json()['data']['certificate']
    pvk = response.json()['data']['private_key']
    pvk_typ = response.json()['data']['private_key_type']

    logger.info("Successfully gotten certificate")
    return (cert, pvk)
