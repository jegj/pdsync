# pdsync
personal data sync script

## usage

```sh 
dsync.sh -d /backup /home/user/folder1 /home/user/folder2
dsync.sh -d "/media/backups" /home/user1/Videos /home/user1/Documents /home/user1/Pictures /home/user1/projects
```
On crons define the XDG_RUNTIME_DIR so the cron can send the notification

```sh
* * * * * XDG_RUNTIME_DIR=/run/user/$(id -u) dsync.sh -d "/remote/backup" /home
```

## Installation

```sh
cp dsync.sh $HOME/.local/bin
```

