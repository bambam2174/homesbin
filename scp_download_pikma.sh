#!/bin/bash
function foo() {
	scp root@pikmahosting.de:/var/www/vhosts/pikmahosting.de/$1 ./
}
foo 'apps.pikmahosting.de/index.php'

