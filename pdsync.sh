#!/bin/bash
set -o pipefail
#######################################################################################################################
#                                            pdsync                                                                   #
# Script to backup my data and upload it to remote locations                                                          #
#                                                                                                                     #
# Author: jegj@gmail.com                                                                                              #
#                                                                                                                     #
# Usage:                                                                                                              #
# ./pdsync.sh /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                           #
# ./pdsync.sh -d /tmp /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                   #
#######################################################################################################################

day_in_ms=86400000
tar_failed=0
usage() {
	cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
		basename "${BASH_SOURCE[0]}"
	) [-h|--help] [-v|--verboese] [-b|--backup_name <backup_name>] [-d|--destination <destination>] [-p|--prune <prune_days>] arg1 [arg2...]

Script to backup my data and upload it to remote locations

Available options:

-h, --help         Print this help and exit
-v, --verbose      Print script debug info
-b, --backup_name  Backup's name. By default create a generic name with the timestamp
-d, --destination  Final destination for the backup. By default is the current directory
-p, --prune        Prune backups based on days created     
-s, --s3_bucket    S3 bucket for offsite backup     
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
}

parse_params() {
	# default values of variables set from params
	backup_name="backup_$(date +%d_%m_%Y).tar.xz"
	folder_destination="./"
	prune_days=0
	s3_bucket=''
	arrVar=()

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
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

parse_params "$@"
start=$(date +%s.%N)

{
	check_dependecies
	if ! XZ_OPT=-9 tar --exclude-vcs --exclude="node_modules" -Jcvf "$folder_destination/$backup_name" "${arrVar[@]}"; then
		tar_failed=1
	fi
	duration=$(echo "$(date +%s.%N) - $start" | bc)
	execution_time=$(printf "%.2f seconds" "$duration")
	if [[ $tar_failed -eq 0 ]]; then
		notify-send -u normal -a pdsync -c backups -t $day_in_ms "pdsync backup completed. Execution time: $execution_time"
	else
		notify-send -u critical -a pdsync -c backups -t $day_in_ms "pdsync backup failed"
	fi
	echo "Backup generation completed. Execution time: $execution_time"

	if [[ $prune_days -gt 0 ]]; then
		echo "prune active for $prune_days at $folder_destination"
		find "$folder_destination" -mtime "+$prune_days" -type f -delete
	fi
	if
		[[ -z "$s3_bucket" ]]
	then
		echo "No s3 bucket. Skipping remote backup..."
	else
		echo "Preparing to upload to S3 bucket $s3_bucket"
		# TODO: Delete old backups to continue using aws free layer
		if [[ $(date +%u) -eq 7 ]]; then
			aws s3 cp "$folder_destination/$backup_name" "$s3_bucket/jegj_backup.tar.xz"
		else
			echo "Skipping remote backup. Only on Sundays"
		fi
	fi
} >"/tmp/$backup_name.out" 2>"/tmp/$backup_name.err"
