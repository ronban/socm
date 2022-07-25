#Used only for development
import os,logging
from flask import Flask
from flaskAppServer import proxy
from flaskAppServer.apperrhandler import AppException,handle_app_exception

app = Flask(__name__)

# code

if __name__ == '__main__':
    # guaranteed to not be run on a production server
    app.register_blueprint(proxy.bp)
    app.register_error_handler(AppException, handle_app_exception)
    app.run(port=5001,debug=True)