<source>
  @type forward
  port ${logger_port}
  bind 0.0.0.0
</source>

<source>
    @type syslog
    port ${syslogger_port}
    tag nginx.access
</source>

<source>
    @type syslog
    port ${syslogger2_port}
    tag vault.access
</source>

<match odata-proxy.**>
  @type copy
  <store>
    @type file
    path /fluentd/log/socm-odata
    <format>
      localtime false
    </format>
    <buffer time>
      timekey_wait 10m
      timekey 86400
      timekey_use_utc true
      path /fluentd/log/socm-odata-buffer
    </buffer>
    <inject>
      time_format %Y%m%dT%H%M%S%z
      localtime false
    </inject>
  </store>
  <store>
    @type stdout
  </store>
</match>

<match nginx.**>
  @type copy
  <store>
    @type file
    path /fluentd/log/socm-ingress
    <format>
      localtime false
    </format>
    <buffer time>
      timekey_wait 10m
      timekey 86400
      timekey_use_utc true
      path /fluentd/log/socm-ingress-buffer
    </buffer>
    <inject>
      time_format %Y%m%dT%H%M%S%z
      localtime false
    </inject>
  </store>
  <store>
    @type stdout
  </store>
</match>

<match vault.**>
  @type copy
  <store>
    @type file
    path /fluentd/log/socm-vault
    <format>
      localtime false
    </format>
    <buffer time>
      timekey_wait 10m
      timekey 86400
      timekey_use_utc true
      path /fluentd/log/socm-vault-buffer
    </buffer>
    <inject>
      time_format %Y%m%dT%H%M%S%z
      localtime false
    </inject>
  </store>
  <store>
    @type stdout
  </store>
</match>