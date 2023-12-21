# Bootstrap NixOS

```shell
# Local machine
$ ./serve.sh

# Remote machine
$ curl http://x.x.x.x:9000 | sudo bash -s /dev/disk/by-id/DISK
# Wait for install
$ sudo shutdown -r now

# Local machine
$ ./first-deploy.sh hostname x.x.x.x
$ deploy .#hostname
```
