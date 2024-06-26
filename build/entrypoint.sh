#!/bin/bash

if [[ "$*" =~ --debug ]]; then
    set -x
fi
set -e
set -o pipefail


# rust-specifics
chmod -R 777 /opt/rust/ >> /dev/null 2>&1 || true

export METERIAN_CLI_ARGS=$*
export ORIGINAL_PATH=$PATH

# retrieve host uid and host gid from /workspace
if [[ -d "/workspace"  ]]; then
    workspace_uid=$(stat -c '%u' /workspace)
    workspace_gid=$(stat -c '%g' /workspace)
fi

# prepare command options with the host uid and gid when present or prepare them with retrieved ones
WITH_HUID=""
WITH_HGID=""
if [[ -n "${HOST_UID}" && -n "${HOST_GID}" ]];
then
    WITH_HGID="-g ${HOST_GID} -o"
    WITH_HUID="-ou ${HOST_UID}"
elif [[ -n "${workspace_gid:-}" ]]; then
    WITH_HGID="-g ${workspace_gid} -o"
    WITH_HUID="-ou ${workspace_uid}"
fi

# create the user
groupadd ${WITH_HGID} meterian 2>/dev/null || true
useradd -g meterian ${WITH_HUID} meterian -d /home/meterian 2>/dev/null || true

# creating home dir if it doesn't exist
if [[ ! -d "/home/meterian" ]];
then
    mkdir /home/meterian
fi

# prep resources in /home/meterian
install -m 775 -o meterian -g meterian /root/meterian.sh /root/version.txt /home/meterian/

# granting permissions to manipulate client jar 
chmod 777 /tmp/meterian-cli-www.jar 2>/dev/null || true

#changing home dir group and ownership
chown meterian:meterian /home/meterian 2>/dev/null || true

# flutter/dart specific prep
if [[ -d "/home/meterian/bin/flutter" ]];then
    chown meterian:meterian /workspace/.dart_tool/ 2>/dev/null || true
    rm -r /workspace/.dart_tool/* 2>/dev/null || true

    chown meterian:meterian /home/meterian 2>/dev/null || true
    chown -R meterian:meterian /home/meterian/bin/flutter/ 2>/dev/null || true 
fi

# launch meterian client with the newly created user
meterian_script=/home/meterian/meterian.sh
if [[ "$*" =~ --debug ]];then
    su meterian -c -m $meterian_script
else
    su meterian -c -m $meterian_script  2>/dev/null
fi

# please do not add any command here as we need to preserve the exit status
# of the meterian client
