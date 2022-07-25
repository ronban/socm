version: 1
disable_existing_loggers: true
formatters:
    brief:
        format: '%(message)s'
    default:
        format: '%(asctime)s %(levelname)-8s %(name)-15s %(message)s'
        datefmt: '%Y-%m-%d %H:%M:%S'
    fluent_fmt:
        '()': fluent.handler.FluentRecordFormatter
        format:
            level: '%(levelname)s'
            hostname: '%(hostname)s'
            where: '%(module)s.%(funcName)s'

handlers:
    console:
        class : logging.StreamHandler
        level: ${log_level}
        formatter: default
        stream: ext://sys.stdout
    fluent:
        class: fluent.handler.FluentHandler
        host: ${logger_host}
        port: ${logger_port}
        tag: odata-proxy
        buffer_overflow_handler: overflow_handler
        formatter: fluent_fmt
        level: ${log_level}
    none:
        class: logging.NullHandler

loggers:
    flaskAppServer.main:
        handlers: [fluent,console]
        propagate: False
    flaskAppServer.proxy:
        handlers: [fluent,console]
        propagate: False
    flaskAppServer.authenticate:
        handlers: [fluent,console]
        propagate: False
    urllib3:
        handlers: [fluent,console]
        level: ${log_level}
        propagate: True
    '': # root logger
        handlers: [console, fluent]
        level: ${log_level}
        propagate: False