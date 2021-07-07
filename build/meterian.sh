#!/bin/sh

# Adjusting PATH so that all needed tools are found
echo 'export PATH=${ORIGINAL_PATH}' >> ~/.bashrc

# Rust user-specific configuration setup
echo 'export RUSTUP_HOME=/opt/rust/rustup' >> ~/.bashrc
source ~/.bashrc


CLIENT_ENV=${CLIENT_ENV:-"www"}

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
		echo " Please create a token from your account at https://meterian.com/account/#tokens "
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

updateClient() {
	METERIAN_JAR_PATH=$1
	CLIENT_TARGET_URL=$2

	LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS="$(getLastModifiedDateTimeForFileInSeconds $METERIAN_JAR_PATH)"
	REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS="$(date -d "$(curl -s -L -I "${CLIENT_TARGET_URL}" | grep Last-Modified: | cut -d" " -f2-)" +%s)"
	if [[ ${REMOTE_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} -gt ${LOCAL_CLIENT_LAST_MODIFIED_DATE_IN_SECONDS} ]];
	then
		echo Updating the client$(test -n "${CLIENT_CANARY_FLAG}" && echo " canary" || true)...
		curl -s -o "${METERIAN_JAR_PATH}" "${CLIENT_TARGET_URL}"  >/dev/null
	fi
}

INDEPENDENT_METERIAN_CLI_OPTIONS='--version\|--help\|--detect'
VERSION_FLAG_REGEXP='--version'

# dump docker packaged version unless '--version' requested
if [[ $(regexMatch "${METERIAN_CLI_ARGS}" $VERSION_FLAG_REGEXP) -eq 0 ]]; then
	cat /tmp/version.txt
	exitWithErrorMessageWhenApiTokenIsUnset
fi

# meterian jar location
METERIAN_JAR="/tmp/meterian-cli-${CLIENT_ENV}.jar"

# download canary client if flag is set
if [[ -n "${CLIENT_CANARY_FLAG}" ]];
then
	METERIAN_JAR=/tmp/meterian-cli-canary.jar
	# update cli-canary if necessary
	updateClient "${METERIAN_JAR}" "https://${CLIENT_ENV}.meterian.io/downloads/meterian-cli-canary.jar"
	
else
	# update the client if necessary
	updateClient "${METERIAN_JAR}" "https://${CLIENT_ENV}.meterian.com/downloads/meterian-cli.jar"
fi

# launching the client - note the different launch if version requested to preserve the "--version" base functionality
cd /workspace || true
if [[ -n "${METERIAN_API_TOKEN:-}" || $(regexMatch "${METERIAN_CLI_ARGS:-}" $INDEPENDENT_METERIAN_CLI_OPTIONS) -gt 0 ]];
then
	java $(echo "${CLIENT_VM_PARAMS}") -jar ${METERIAN_JAR} ${METERIAN_CLI_ARGS:-} --interactive=false
fi
# storing exit code
client_exit_code=$?

# dump docker packaged version, right after the client version if the --version option was specified
if [[ $(regexMatch "${METERIAN_CLI_ARGS}" $VERSION_FLAG_REGEXP) -gt 0 ]];then
    cat /tmp/version.txt        # 0 exit code but it's okay
fi

exit "$client_exit_code"

# please do not add any command here as we need to preserve the exit status
# of the meterian client
