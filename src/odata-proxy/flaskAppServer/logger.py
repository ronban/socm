from http.client import HTTPConnection

import msgpack
from io import BytesIO
import os
import yaml
import logging.config
import logging
import coloredlogs
import contextlib

def setup_logging(default_path='/app/flaskAppServer/logging.yaml', default_level=logging.INFO, env_key='LOG_CFG'):
    """
    | **@author:** wLabs
    | Logging Setup
    """
    # path = default_path
    # value = os.getenv(env_key, None)

    # if value:
    #     path = value
    # if os.path.exists(path):
    #     with open(path, 'rt') as f:
    #         try:
    #             config = yaml.safe_load(f.read())
    #             logging.config.dictConfig(config)
    #             coloredlogs.install()
    #         except Exception as e:
    #             print(e)
    #             print('Error in Logging Configuration. Using default configs')
    #             logging.basicConfig(level=default_level)
    #             coloredlogs.install(level=default_level)
    # else:
    #     logging.basicConfig(level=default_level)
    #     coloredlogs.install(level=default_level)
    #     print('Failed to load configuration file. Using default configs')

    with open(default_path, 'rt') as file:
        config = yaml.safe_load(file.read())
        logging.basicConfig(level=default_level)
        logging.config.dictConfig(config)

def overflow_handler(pendings):
    unpacker = msgpack.Unpacker(BytesIO(pendings))
    for unpacked in unpacker:
        print(unpacked)