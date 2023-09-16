# pdsync
personal data sync script

## usage

```sh 
pdsync.sh -d /backup /home/user/folder1 /home/user/folder2
pdsync.sh -d "/media/backups" -s s3://my-backups /home/user1/Videos /home/user1/Documents /home/user1/Pictures /home/user1/projects
pdsync.sh -d "/media/backups" -s s3://my-backups -f -t /home/user1/transition_folder /home/user1/Videos /home/user1/Documents /home/user1/Pictures /home/user1/projects
```
On crons define the XDG_RUNTIME_DIR so the cron can send the notification

```sh
* * * * * XDG_RUNTIME_DIR=/run/user/$(id -u) pdsync.sh -d "/remote/backup" -p 5  -s s3://my-backups /home
```

## remote backups
Only supports s3 and for now only upload the backup to s3 on Sundays to use AWS S3 free layer 

## gpg encryption

```sh
#encryption
gpg --encrypt --sign --armor -r <email> --passphrase-file <passphrase_file> -o <destination> file_name
#descryption
gpg file_name.asc
```

Some documentation about `gpg`

- https://www.digitalocean.com/community/tutorials/how-to-use-gpg-to-encrypt-and-sign-messages
- https://risanb.com/code/backup-restore-gpg-key/

## Installation

```sh
curl -o- https://raw.githubusercontent.com/jegj/pdsync/v1.4.0/install.sh | bash
```
