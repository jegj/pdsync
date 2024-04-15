#!/bin/bash
set -o pipefail
#######################################################################################################################
#                                            pdsync                                                                   #
# Script to backup and encrypt your data in a specific destination with S3 support                                    #
#                                                                                                                     #
# Author: jegj57@gmail.com                                                                                            #
#                                                                                                                     #
# Usage:                                                                                                              #
# ./pdsync.sh /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                           #
# ./pdsync.sh -d /tmp /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                   #
#######################################################################################################################

version="1.6.0"
day_in_ms=86400000
tar_failed=0
usage() {
	cat <<EOF
Version: ${version}
Author: jegj57@gmail.com
Usage: $(
		basename "${BASH_SOURCE[0]}"
	) [-h|--help] [-v|--version] [-b|--backup_name <backup_name>] [-t|--transition_folder <folder>] [-d|--destination <destination>] [-p|--prune <prune_days>] [-s|--s3_bucket <s3 bucket>] [-u|--upload_day <upload day>] [-f|--force_upload] [-e|--gpg_email <email>] [-r|--gpg_passphrase_file <passphrase-file> ] [-c|--clear_s3_bucket] arg1 [arg2...]

Script to backup and encrypt your data in a specific destination with S3 support. 

Dependecies:
 - gpg
 - aws

Available options:

-h, --help                Print this help and exit
-v, --vesion              Print script version
-b, --backup_name         Backup's name with .tar.xz extension( e.g backup.tar.xz). By default create a generic name with the timestamp
-t, ---transition_folder  Transition folder for file/folder operations. Useful when the destination has a file system with file size limitation e.g.vfat
-d, --destination         Final destination for the backup. By default is the current directory
-p, --prune               Prune backups based on days created
-s, --s3_bucket           S3 bucket for offsite backup
-u, --upload_day          Only upload to S3 on specific days base on number( 1-monday, 2-tuesday ...)
-f, --force_upload        Force to upload to S3
-e, --gpg_email           Email for gpg encryption. REQUIRED
-r, --gpg_passphrase_file Passphrase file for gpgp encryption. REQUIRED 
-c, --clear_s3_bucket     Delete the content of the S3 bucket first before upload the backups 
EOF
	exit
}

msg() {
	echo >&2 -e "${1-}"
}

die() {
	local msg=$1
	local code=${2-1} # default exit status 1
	msg "$msg"
	exit "$code"
}

check_dependecies() {
	if ! aws --version &>/dev/null; then
		die "aws cli is required" 1
	fi

	if ! gpg --version &>/dev/null; then
		die "gpg is required" 1
	fi
}

parse_params() {
	# default values of variables set from params
	transition_folder=''
	backup_name="backup_$(date +%d_%m_%Y).tar.xz"
	folder_destination="./"
	prune_days=0
	s3_bucket=''
	upload_day=0
	force_upload=0
	arrVar=()
	gpg_email=''
	gpg_passphrase_file=''
	clear_s3_bucket=0

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --version)
			msg $version
			exit
			;;
		-p | --prune)
			prune_days=${2-}
			shift
			;;
		-b | --backup_name)
			backup_name="${2-}"
			shift
			;;
		-d | --destination)
			folder_destination="${2-}"
			shift
			;;
		-s | --s3_bucket)
			s3_bucket="${2-}"
			shift
			;;
		-u | --upload_day)
			upload_day="${2-}"
			shift
			;;
		-f | --force_upload)
			force_upload=1
			;;
		-t | --transition_folder)
			transition_folder="${2-}"
			shift
			;;
		-e | --gpg_email)
			gpg_email="${2-}"
			shift
			;;
		-r | --gpg_passphrase_file)
			gpg_passphrase_file="${2-}"
			shift
			;;
		-c | --clear_s3_bucket)
			clear_s3_bucket=1
			;;
		-?*) die "Unknown option: $1" ;;
		*)
			[[ -z $1 ]] && break
			arrVar+=("${1}")
			;;
		esac
		shift
	done
	[[ ${#arrVar[@]} -eq 0 ]] && die "The script need the folders for the archive"
	return 0
}

calc_duration() {
	start=$1
	duration_sec=$(echo "$(date +%s) - $start" | bc)
	if [[ "$duration_sec" -gt 60 ]]; then
		duration_min=$(echo "$duration_sec / 60" | bc -l)
		execution_time_min=$(printf "%.2f min" "$duration_min")
		echo "$execution_time_min"
	else
		execution_time_sec=$(printf "%.2f sec" "$duration_sec")
		echo "$execution_time_sec"
	fi
}

check_input() {
	if
		[[ -z "$gpg_email" ]]
	then
		die "gpg_email is required for encryption" 1
	fi

	if
		[[ -z "$gpg_passphrase_file" ]]
	then
		die "gpg_passphrase_file"" is required for encryption" 1
	fi

}

parse_params "$@"
{
	check_dependecies

	check_input

	if [[ -z "$transition_folder" ]]; then
		transition_backup="$folder_destination/$backup_name"
	else
		transition_backup="$transition_folder/$backup_name"
	fi
	encrypted_transition_backup="$transition_backup.asc"

	start_generation=$(date +%s)
	if ! XZ_OPT=-9 tar --exclude-vcs --exclude="node_modules" -Jcvf - "${arrVar[@]}" | gpg --pinentry-mode=loopback --encrypt --sign --armor --batch -r "$gpg_email" --passphrase-file "$gpg_passphrase_file" -o "$encrypted_transition_backup"; then
		tar_failed=1
	fi

	execution_time_seconds=$(calc_duration "$start_generation")
	human_file_size=$(du "$encrypted_transition_backup" -h | cut -f 1)

	if [[ $tar_failed -eq 0 ]]; then
		notify-send -u normal -a pdsync -c backups -t $day_in_ms "pdsync backup completed. Execution time: $execution_time_seconds. File size : $human_file_size"
	else
		notify-send -u critical -a pdsync -c backups -t $day_in_ms "pdsync backup failed"
	fi
	echo "Backup generation completed. Execution time: $execution_time_seconds"

	if [[ $prune_days -gt 0 ]]; then
		echo "prune active for $prune_days at $folder_destination"
		find "$folder_destination" -mtime "+$prune_days" -type f -delete
	fi

	# S3 upload
	if
		[[ -z "$s3_bucket" ]]
	then
		echo "No s3 bucket. Skipping remote backup..."
	else
		start_upload=$(date +%s)
		echo "Preparing to upload to S3 bucket $s3_bucket"
		if [[ $(date +%u) -eq $upload_day || $force_upload -eq 1 ]]; then
			if [[ $clear_s3_bucket -eq 1 ]]; then
				aws s3 rm "$s3_bucket" --recursive
			else
				echo "Skipping s3 clean up..."
			fi
			if ! aws s3 cp "$encrypted_transition_backup" "$s3_bucket"; then
				notify-send -u critical -a pdsync -c backups -t $day_in_ms "pdsync backup upload failed"
			else
				upload_time=$(calc_duration "$start_upload")
				echo "Backup upload completed. Execution time: $upload_time"
			fi
		else
			echo "Skipping remote backup. Does not match the day"
		fi
	fi

	# If there is a transition folder and the file too large( to support my old vfat external drive =/ )
	if [[ -n "$transition_folder" ]]; then
		echo "Moving to final destination...."
		file_size=$(du "$encrypted_transition_backup" | cut -f 1)
		if [[ $file_size -gt 4000000 ]]; then
			echo "File $encrypted_transition_backup too large...splitting file"
			split -n 6 -d -e "$encrypted_transition_backup" "$encrypted_transition_backup.split"
			for i in 0 1 2 3 4 5; do
				echo "Moving chunk $i, $encrypted_transition_backup.split0$i"
				mv "$encrypted_transition_backup.split0$i" "$folder_destination"
			done
			echo "Deleting transition file...$encrypted_transition_backup"
			rm "$encrypted_transition_backup"
		else
			mv "$encrypted_transition_backup" "$folder_destination"
		fi
	fi

} >"/tmp/$backup_name.out" 2>"/tmp/$backup_name.err"
