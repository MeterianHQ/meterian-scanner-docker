#!/bin/bash

if [[ "$METERIAN_CLI_ARGS" =~ --debug ]]; then
    set -x
fi

# Adjusting PATH so that all needed tools are found
echo 'export PATH=${ORIGINAL_PATH}' >> ~/.bashrc

# Rust user-specific configuration setup
echo 'export RUSTUP_HOME=/opt/rust/rustup' >> ~/.bashrc
source ~/.bashrc

# Flutter/Dart specific configuration
if [[ -d "/home/meterian/bin/flutter" ]];then
	echo 'export PATH=${PATH}:/home/meterian/bin/flutter/bin/' >> ~/.bashrc
	source ~/.bashrc

	flutter doctor >> /dev/null 2>&1 || true
	rm -Rf /home/meterian/.pub-cache
fi



# Ensuring legacy env are still supported
METERIAN_ENV=${METERIAN_ENV:-$CLIENT_ENV}
METERIAN_PROTO=${METERIAN_PROTO:-$CLIENT_PROTO}
METERIAN_DOMAIN=${METERIAN_DOMAIN:-$CLIENT_DOMAIN}

METERIAN_ENV=${METERIAN_ENV:-"www"}
METERIAN_PROTO=${METERIAN_PROTO:-"https"}
METERIAN_DOMAIN=${METERIAN_DOMAIN:-"meterian.io"}
CLIENT_AUTO_UPDATE=${CLIENT_AUTO_UPDATE:-"true"}

# uses expr; if something is matched it returns the length of it otherwise 0
regexMatch() {
	text="$1"
	regex=$2
	echo $(expr "$text" : $regex)
}

exitWithErrorMessageWhenApiTokenIsUnset() {
	if [[ -z "${METERIAN_API_TOKEN:-}" && $(regexMatch "${METERIAN_CLI_ARGS}" $INDEPENDENT_METERIAN_CLI_OPTIONS) -eq 0 ]];
	then
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo " The METERIAN_API_TOKEN environment variable must be defined with an API token   "
		echo
		echo " Please create a token from your account at ${METERIAN_PROTO}://${METERIAN_ENV}.${METERIAN_DOMAIN}/dashboard/#tokens "
		echo " and populate the variable with the value of the token "
		echo
		echo " For example: "
		echo " export METERIAN_API_TOKEN=12345678-90ab-cdef-1234-567890abcdef "
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-"
		exit -1
	fi
}

getLastModifiedDateTimeForFileInSeconds() {
	MAYBE_FILE=$1

	WHEN=`date -r $MAYBE_FILE +"%s" 2>/dev/null`
	if [[ $? -gt 0 ]]; then
		WHEN="$(date -d "1999-01-01" +%s)"
	fi

	# returning the value of $WHEN ( common way of returning data from functions in bash )
	echo $WHEN
}

isClientJarCorrupted() {
	METERIAN_JAR="$1"
	java -jar ${METERIAN_JAR} --version >> /dev/null 2>&1
	if [[ "$?" != "0" ]];then
		echo "true"
	else
		echo "false"
	fi
}

updateClient() {
	if [[ "${CLIENT_AUTO_UPDATE}" == "false" && "${METERIAN_ENV}" != "qa" ]]; then
		return
	fi

	METERIAN_JAR_PATH=$1
	CLIENT_TARGET_URL=$2

	LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS="$(getLastModifiedDateTimeForFileInSeconds $METERIAN_JAR_PATH)"
	REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS="$(date -d "$(curl -s -L -I "${CLIENT_TARGET_URL}" | grep Last-Modified: | cut -d" " -f2-)" +%s)"
	if [[ "$(isClientJarCorrupted "$METERIAN_JAR_PATH")" == "true" || ${REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} -gt ${LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} ]];
	then
		echo Updating the client$(test -n "${CLIENT_CANARY_FLAG}" && echo " canary" || true)...
		curl -s -o "${METERIAN_JAR_PATH}" "${CLIENT_TARGET_URL}"  >/dev/null
	fi
}

INDEPENDENT_METERIAN_CLI_OPTIONS='.*--version.*\|.*--help.*\|.*--detect.*\|.*--oss.*\|.*--no-analysis.*'
VERSION_FLAG_REGEXP='.*--version.*'

# dump docker packaged version unless '--version' requested
if [[ $(regexMatch "${METERIAN_CLI_ARGS}" $VERSION_FLAG_REGEXP) -eq 0 ]]; then
	cat ~/version.txt
	exitWithErrorMessageWhenApiTokenIsUnset
fi

# meterian jar location
METERIAN_JAR=""
METERIAN_JAR_URL=""

# select canary client if flag is set
if [[ -n "${CLIENT_CANARY_FLAG}" ]];
then
	METERIAN_JAR=/tmp/meterian-cli-${METERIAN_ENV}-canary.jar
	METERIAN_JAR_URL="${METERIAN_PROTO}://${METERIAN_ENV}.${METERIAN_DOMAIN}/downloads/meterian-cli-canary.jar"

else
	METERIAN_JAR="/tmp/meterian-cli-${METERIAN_ENV}.jar"
	METERIAN_JAR_URL="${METERIAN_PROTO}://${METERIAN_ENV}.${METERIAN_DOMAIN}/downloads/meterian-cli.jar"
fi

# update the client if necessary
updateClient "${METERIAN_JAR}" "${METERIAN_JAR_URL}"

if [[ ! -f ${METERIAN_JAR} ]]; then
	if [[ "${CLIENT_AUTO_UPDATE}" == "false" ]]; then
		echo "Error: CLIENT_AUTO_UPDATE must be enabled to download the $METERIAN_ENV client"
	else
		echo "Unexpected error: client update failed via url: ${METERIAN_JAR_URL}"
		echo "Please ensure connections to ${METERIAN_JAR_URL} are permitted from the Docker container"
	fi
fi

# launching the client - note the different launch if version requested to preserve the "--version" base functionality
cd /workspace || true
if [[ -n "${METERIAN_API_TOKEN:-}" || $(regexMatch "${METERIAN_CLI_ARGS:-}" $INDEPENDENT_METERIAN_CLI_OPTIONS) -gt 0 ]];
then
	if [[ $(regexMatch "${METERIAN_CLI_ARGS}" '.*--oss.*') -gt 0 ]];then
		CLIENT_VM_PARAMS="${CLIENT_VM_PARAMS} -Dcli.oss.enabled=true"
	fi
	java -Ddockerized.workspace=/workspace $(echo "${CLIENT_VM_PARAMS}") -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS:-} --interactive=false
fi
# storing exit code
client_exit_code=$?

# dump docker packaged version, right after the client version if the --version option was specified
if [[ $(regexMatch "${METERIAN_CLI_ARGS}" $VERSION_FLAG_REGEXP) -gt 0 ]];then
    cat ~/version.txt        # 0 exit code but it's okay
fi

exit "$client_exit_code"

# please do not add any command here as we need to preserve the exit status
# of the meterian client
