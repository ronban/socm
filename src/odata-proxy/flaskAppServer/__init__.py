import os, logging

from flask import Flask
from flaskAppServer import proxy
from flaskAppServer.logger import setup_logging
from flaskAppServer.apperrhandler import AppException,handle_app_exception


LOG_LEVEL = os.environ['LOG_LEVEL']

def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__,instance_relative_config=True)

    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # Setup Logging
    setup_logging(default_level=LOG_LEVEL)

    # Apply the blueprints to the app
    app.register_blueprint(proxy.bp)
    
    # Register exceptions
    app.register_error_handler(AppException, handle_app_exception)

    return app
