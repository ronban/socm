import json
import jwt
import os
import requests
import logging
from functools import wraps
from cryptography.x509 import load_pem_x509_certificate
from cryptography.hazmat.backends import default_backend
from flask import Flask, request

from flaskAppServer.apperrhandler import AppException


APP_ID      = os.environ['AZURE_CLIENT_ID']
JWKS_URI    = os.environ['AZURE_JWKSURI']
ISS         = os.environ['AZURE_ISSUER']

logger = logging.getLogger(__name__)

# decorator for verifying the JWT
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        # jwt is passed in the request header
        if 'Authorization' in request.headers:
            token = request.headers['Authorization']
        # return 401 if token is not passed
        if not token:
            logger.error("Authorization Bearer token missing")
            raise AppException(Exception('No Bearer Token'),status_code=401)
  
        try:
            access_token = str.replace(str(token), 'Bearer ', '')
            current_user = validate_token(access_token)
        
        except jwt.exceptions.ExpiredSignatureError as ex1:
            logger.error("Authorization Bearer token expired")
            raise AppException(ex1, status_code=403)
        except jwt.exceptions.InvalidAudienceError as ex2:
            logger.error("Authorization Bearer token has invalid audience."
                        "Check Scope used from consumer app.")
            raise AppException(ex2,status_code=403)

        # returns the current logged in users contex to the routes
        return  f(access_token,current_user, *args, **kwargs)
  
    return decorated

def validate_token(access_token):
    logger.info("Validating JWT")
    access_token_header = jwt.get_unverified_header(access_token)
    res = requests.get(JWKS_URI)
    if res.status_code != 200:
        logger.error("Error reaching out to JWKS URI - %s", JWKS_URI)
        logger.debug("Error code %d with message %s for %s", res.status_code, res.json(), JWKS_URI)
        raise AppException(Exception('JWSURI not accessible'),status_code=501)
    jwk_keys = res.json()

    x5c = None

    # Iterate JWK keys and extract matching x5c chain
    for key in jwk_keys['keys']:
        if key['kid'] == access_token_header['kid']:
            x5c = key['x5c']

    cert = ''.join([
        '-----BEGIN CERTIFICATE-----\n',
        x5c[0],
        '\n-----END CERTIFICATE-----\n',
    ])
    public_key = load_pem_x509_certificate(cert.encode(), default_backend()).public_key()

    token = jwt.decode(
        access_token,
        public_key,
        algorithms='RS256',
        audience=APP_ID,
        options={"require": ["exp", "iss", "sub"]}
    )

    logger.info("Successfully verified and decoded token")
    logger.debug("JWT Token details - %s", token)

    # if USER_KEY not in token:
    #     logger.error("User Key %s not in JWT. Check Configuration", USER_KEY)
    #     logger.debug("Token expanded %s", token)
    #     raise AppException(Exception('User Key not in JWT. Check Configuration'),status_code=502)

    # current_user = {
    #                 "oid": token['oid'],
    #                 "sub": token['sub'],
    #                 "user_key": token[USER_KEY]
    #             }

    return token