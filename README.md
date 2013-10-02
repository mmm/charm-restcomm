

    juju bootstrap
    juju deploy mobicents restcomm
    juju deploy mobicents mediaserver

    juju add-relation restcomm:restcomm mediaserver:mediaserver


# TODO

- move builds to config or even install
  optional or not?

- just do installs and config at relation-time so they finish faster


- mediaserver config to bind to interfaces other than localhost

- restcomm config to use the external mediaserver


