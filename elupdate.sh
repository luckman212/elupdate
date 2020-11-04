#!/usr/bin/env bash

# Eclectic Light updater
# https://github.com/luckman212/elupdater
# https://github.com/hoakleyelc/updates

_die() {
	echo "$1"
	exit $2
}

_jqinst() {
	if [ ! -e ./jq ]; then
		if ! curl -Ls -o ./jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64; then
			_die "could not download jq automatically, please run \`brew install jq\` if you have Homebrew installed, or visit https://stedolan.github.io/jq to download manually" 1
		fi
	fi
	chmod +x ./jq
	jqcmd=./jq
}

_check() {
	local appname realappname zipname ver_override url latest_ver cur_ver cur_app_path cur_app_container
	appname=$1
	realappname=$2
	zipname=$3
	ver_override=$4
	[ -n "$zipname" ] || return
	if [ -n "$ver_override" ]; then
		latest_ver="$ver_override"
	else
		latest_ver=$($jqcmd -r --arg app "$1" '.[] | select(.AppName==$app) | .Version' <<<"$json")
	fi
	if [ -z "$latest_ver" ]; then
		echo "version information not available for $1, and no override was specified"
		return
	fi
	url=$($jqcmd -r --arg app "$1" '.[] | select(.AppName==$app) | .URL' <<<"$json")
	cur_app_path=$(find "$DST_FOLDER" -type d -maxdepth 2 -name "$realappname" 2>/dev/null | head -n1)
	cur_app_container=$(find "$DST_FOLDER" -type d -maxdepth 1 -name "$zipname*" 2>/dev/null | head -n1)
	if [ -n "$cur_app_path" ]; then
		cur_ver=$(/usr/bin/plutil -convert json -o - "$cur_app_path/Contents/Info.plist" | $jqcmd -r .CFBundleShortVersionString)
	else
		cur_ver=0
	fi
	if [[ $latest_ver != "$cur_ver" ]]; then
		if [ -n "$ver_override" ]; then
			echo "$1 must be installed manually"
			(( MCOUNT++ ))
			return
		fi
		_install "$appname" "$realappname" "$cur_app_container" "$url"
		return
	else
		echo "$appname ($latest_ver) is current"
	fi
}

_install() {
	local appname=$1
	local realappname=$2
	local cur_app_container="$3"
	local url=$4
	local zip_filename=${url##*/}
	local foldername=${zip_filename%.zip}
	[ -n "$url" ] || return

	# is app running?
	APP_PID=$(pgrep -f "$2/")
	[ -z "$APP_PID" ] || _die "skipping $realappname because it's running" 1

	# download
	curl -s -L -o "${DL_PATH:?}/${zip_filename:?}" "$url"
	unzip -qo "${DL_PATH:?}/${zip_filename:?}" -d "${DL_PATH}" -x '__MACOSX/*' 2>/dev/null
	if [ -d "${cur_app_container}" ]; then
		if ! rm -r "${cur_app_container:?}"; then
			_die "error removing existing app" 1
		fi
	fi
	if cp -Rp "${DL_PATH}/${foldername:?}" "$DST_FOLDER"; then
		echo "$appname has been updated"
		rm -r "${DL_PATH}/${foldername:?}"
		rm "${DL_PATH:?}/${zip_filename:?}"
	fi
}

# env vars
DL_PATH=$HOME/Downloads
PLIST=https://raw.githubusercontent.com/hoakleyelc/updates/master/eclecticapps.plist
MANUAL=https://eclecticlight.co/updates-sierra-and-high-sierra/
CFGFILE=eclecticlight_config.txt
DST_FOLDER="$HOME/Applications"
MCOUNT=0

# prereq checks
mkdir -p "$DST_FOLDER"
[ -d "$DST_FOLDER" ] || _die "destination folder does not exist ($DST_FOLDER)" 1
[ -e "$CFGFILE" ] || _die "missing config file ($CFGFILE)" 1
jqcmd=$(command -v jq)
[ -x "$jqcmd" ] || _jqinst

# fetch versions
json=$(curl -s -o- ${PLIST} | /usr/bin/plutil -convert json -o - -- -)
if [[ -z "$json" ]] || [[ "$json" == "null" ]]; then
	_die "error getting latest release data from github" 1
fi

# main loop
while IFS=\| read -r AppName RealAppName ZipName LatestVerOverride; do
	[ "$ZipName" ] || continue
	[ "${AppName:0:1}" != "#" ] || continue
	_check "$AppName" "$RealAppName" "$ZipName" "$LatestVerOverride"
done <"$CFGFILE"
if [ $MCOUNT -gt 0 ]; then
	echo "==> visit $MANUAL to download apps manually"
fi
