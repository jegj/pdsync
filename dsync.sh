#!/bin/bash
set -e
set -o pipefail
#######################################################################################################################
#                                            dsync                                                                    #
# Script to backup my data and upload it to remote locations                                                          #
#                                                                                                                     #
# Author: jegj@gmail.com                                                                                              #
#                                                                                                                     #
# Usage:                                                                                                              #
# ./dsync.sh /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                            #
# ./dsync.sh -d /tmp /home/jegj/Videos /home/jegj/Pictures/  /home/jegj/Documents/                                    #
#######################################################################################################################

usage() {
	cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
		basename "${BASH_SOURCE[0]}"
	) [-h|--help] [-v|--verboese] [-b|--backup_name <backup_name>] [-d|--destination <destination>] arg1 [arg2...]

Script to backup my data and upload it to remote locations

Available options:

-h, --help         Print this help and exit
-v, --verbose      Print script debug info
-b, --backup_name  Backup's name. By default create a generic name with the timestamp
-d, --destination  Final destination for the backup. By default is the current directory
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

parse_params() {
	# default values of variables set from params
	backup_name="backup_$(date +%d_%m_%Y).tgz"
	folder_destination="./"
	arrVar=()

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		-b | --backup_name)
			backup_name="${2-}"
			shift
			;;
		-d | --destination)
			folder_destination="${2-}"
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

# TODO: Replace hardcoded name
#if [[ "$(whoami)" != "root" ]]; then
#	die "Script must be run as the owner "255
#fi

{
	tar -czvf "$folder_destination/$backup_name" "${arrVar[@]}"
}

duration=$(echo "$(date +%s.%N) - $start" | bc)
execution_time=$(printf "%.2f seconds" "$duration")
echo "Script Execution Time: $execution_time"
