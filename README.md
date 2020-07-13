# simplesquid
Dockerized simple squid proxy

## Overview

Super simple squid web proxy.

### Getting started

#### Get the container

```bash
docker pull krayzpipes/simplesquid:latest
```

#### Configure the container

There are a couple options to configure the simple squid proxy:

1. Create you own build and add your squid configuration.
2. Use environment variables at runtime.

##### Create your own build

```Dockerfile
FROM krayzpipes/simplesquid:latest

COPY squid.conf /etc/squid/
```

##### Use environment variables at runtime

- Supported environment variables:

    - `ALLOWED_SRC_CIDRS`
        - Space-delimited list of CIDRs which will be allowed to use
        the proxy.
        - Ex: `127.0.0.0/8 192.168.0.0/16 172.16.0.0/12`
    - `DENIED_DST_CIDRS`
        - Space-delimited list of CIDRs which will client will
        be denied access to.
        - Ex: `127.0.0.0/8 192.168.0.0/16 172.16.0.0/12`
    - `DENIED_DOMAINS`
        - Space-delimited list of domain names which client
        will be denied access to.
        - Ex: `.google.com .twitter.com .facebook.com`
    - `SQUID_CREDS`
        - Pipe-delimited list of username and password pairs.
        - If this variable is missing, then no authentication will
        be required to use the proxy.
        - The passwords will be added to the squid password file
        via the `htpasswd` command from `apache-utils`.
        - Ex: `user1 pass1|user2 pass2|usern passn`

#### Run and use a single container
 - Run it
    ```bash
    docker run -e ALLOWED_SRC_CIDRS="127.0.0.1/32 192.168.0.0/16 10.50.10.0/24" \
        --env DENIED_DST_CIDRS="127.0.0.0/8 10.10.10.0/24" \
        --env DENIED_DOMAINS=".google.com .twitter.com .facebook.com" \
        --env SQUID_CREDS="user1 pass1|user2 pass2" \
        --expose 127.0.0.1:3128:3128
        krayzpipes/simplesquid:latest
    ```
 - Use it
 
    - Successful attempt
        ```python
        >>> import requests
        >>>
        >>> # Successful attempt
        >>> proxies = {'http': 'http://user1:pass2@127.0.0.1:3128', 'https': 'http://user1:pass2@127.0.0.1:3128'}
        >>> r = requests.get('http://mysite.local', proxies=proxies)
        >>> r.status_code
        200
        >>> r.reason
        OK
        ```
      
    - Whoops, forgot my credentials...
        ```python
        >>> proxies = {'http': 'http://127.0.0.1:3128', 'https': 'http://127.0.0.1:3128'}
        >>> r = requests.get('http://mysite.local', proxies=proxies)
        >>> r.status_code
        407
        >>> r.reason
        Proxy Authentication Required
        ```
      
    - Not allowed to the destination domain
        ```python
        >>> proxies = {'http': 'http://user1:pass1@127.0.0.1:3128', 'https': 'http://user1:pass1@127.0.0.1:3128'}
        >>> r = requests.get('http://mail.google.com', proxies=proxies)
        >>> r.status_code
        403
        >>> r.reason
        Forbidden
        ```

#### Viewing access logs

Here a few (but not all) possible ways to get access to the access logs:

1. Bind mount a directory on your host to the `/var/log/squid/` directory in the container.
2. Use a side-car to view/export logs
    - See the `docker-compose.yml` file that is part of this repository as an example.
    - This requires a shared volume for both the simplesquid and fluentd container as well as
    makin sure the `fluent` user has the same `gid` as the group that has permissions to the
    access log file on the simplesquid container.