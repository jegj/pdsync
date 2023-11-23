#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #
	pdsync_version=${PDSYNC_VERSION:-"v1.6.0"}
	msg() {
		command printf %s\\n "$*" 2>/dev/null
	}

	has_dependecy() {
		type "$1" >/dev/null 2>&1
	}

	pdsync_echo() {
		command printf %s\\n "$*" 2>/dev/null
	}

	script_download() {
		if has_dependecy "curl"; then
			curl --fail --compressed -q "$@"
		elif has_dependecy "wget"; then
			# Emulate curl with wget
			ARGS=$(pdsync_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
				-e 's/--compressed //' \
				-e 's/--fail //' \
				-e 's/-L //' \
				-e 's/-I /--server-response /' \
				-e 's/-s /-q /' \
				-e 's/-sS /-nv /' \
				-e 's/-o /-O /' \
				-e 's/-C - /-c /')
			# shellcheck disable=SC2086
			eval wget $ARGS
		fi
	}

	pdsync_install() {
		local url="https://raw.githubusercontent.com/jegj/pdsync/$pdsync_version/pdsync.sh"
		if ! script_download -o "$HOME/.local/bin/pdsync" "$url"; then
			msg >&2 "Failed to install pdsync"
			exit 1
		fi
		chmod a+x "$HOME/.local/bin/pdsync"
	}

	if [ -z "${BASH_VERSION}" ] || [ -n "${ZSH_VERSION}" ]; then
		# shellcheck disable=SC2016
		msg >&2 'Error: the install instructions explicitly say to pipe the install script to `bash`; please follow them'
		exit 1
	fi

	pdsync_install

} # this ensures the entire script is downloaded #
