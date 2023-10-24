# pdsync
personal data sync script. Script that backups folder on an external hard drive and also upload them to S3. By default all the logs go to the `/tmp`folder.

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
## gpg encryption
`pdsync` use gpg encryption, so this is a basic way to encryp/decrypt files
```sh
#encryption
gpg --encrypt --sign --armor -r <email> --passphrase-file <passphrase_file> -o <destination> file_name
#descrypt
gpg file_name.asc
```

Some documentation about `gpg`

- https://www.digitalocean.com/community/tutorials/how-to-use-gpg-to-encrypt-and-sign-messages
- https://risanb.com/code/backup-restore-gpg-key/
- https://www.howtogeek.com/816878/how-to-back-up-and-restore-gpg-keys-on-linux/

## Installation

```sh
curl -o- https://raw.githubusercontent.com/jegj/pdsync/v1.5.1/install.sh | bash
```

Install the script at `$HOME/.local/bin/pdsync`
