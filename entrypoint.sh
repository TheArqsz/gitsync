#!/usr/bin/env bash

if [ ! -z "${VERBOSE}" ]; then
    set -x
fi

WORKDIR="$WORKSPACE"

git config --global --add safe.directory $WORKDIR

echo "## Changing workdir to $WORKDIR" && cd $WORKDIR

if ! $(git rev-parse --is-inside-work-tree &>/dev/null); then
    echo ">> $WORKDIR is not a valid GIT repository - exiting" 
    exit 1
fi

# Working within the GIT repo

REMOTE_ORIGIN="$(git config --local --get remote.origin.url 2>/dev/null)"

if [ -z "${REMOTE_ORIGIN}" ]; then
    echo ">> $WORKDIR is not a valid GIT repository - exiting" 
    exit 1
fi

if [[ $REMOTE_ORIGIN != "http://"* ]] && [[ $REMOTE_ORIGIN != "https://"* ]]; then
    echo "## [$(date +%Y-%m-%dT%H:%M:%SZ)] Working with a SSH remote"
    SSH_PRIVATE_KEY_FILE=${SSH_PRIVATE_KEY_FILE:-/id_rsa}
    if [ -z "${SSH_PRIVATE_KEY_FILE}" ]; then
        echo ">> SSH_PRIVATE_KEY_FILE variable is not set - exiting"
        exit 1
    elif [ ! -f $SSH_PRIVATE_KEY_FILE ]; then
        echo ">> SSH_PRIVATE_KEY_FILE is not a valid file - exiting"
        exit 1
    else
        cp "$SSH_PRIVATE_KEY_FILE" /root/.ssh/id_rsa
        chmod 600 /root/.ssh/id_rsa
    fi
fi


# Fill the creds if needed
if [[ $BASIC_AUTH -eq 1 ]]; then
    if [ -z "${USERNAME}" ]; then
        echo ">> Username not set - exiting"
        exit 1
    fi
    if [ ! -f "${PASSWORD_OR_KEY_FILE}" ]; then
        echo ">> Password or API Key secret is not set - exiting"
        exit 1
    fi
    git config --global credential.helper cache
    git config --global credential.$REMOTE_ORIGIN.username $USERNAME
    cat <<EOT >> /git-askpass.sh 
    echo "$(cat $PASSWORD_OR_KEY_FILE)"
EOT
    chmod +x /git-askpass.sh
    export GIT_ASKPASS=/git-askpass.sh
fi

# Main functionality

MAIN_BRANCH=${MAIN_BRANCH:-main}
TIMEOUT=${TIMEOUT:-60}

git config --local core.sharedRepository group

CURRENT_OWNER_UID=$(stat -c '%u' .git/)
CURRENT_OWNER_GID=$(stat -c '%g' .git/)

while [ true ]
do
    echo "## [$(date +%Y-%m-%dT%H:%M:%SZ)] Synchronizing the remote repository from $REMOTE_ORIGIN"
    git fetch --all &>/dev/null
    if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
        echo "## [$(date +%Y-%m-%dT%H:%M:%SZ)] No remote changes detected"
    else
        git stash -q
        files_to_be_changed=$(git diff --name-only ..origin/$(git rev-parse --abbrev-ref HEAD))
        git pull origin $MAIN_BRANCH --force
        while IFS= read -r f; do
            chown -R $CURRENT_OWNER_UID:$CURRENT_OWNER_GID "$f"
        done <<< "$files_to_be_changed"

    fi
    echo "## [$(date +%Y-%m-%dT%H:%M:%SZ)] Sleeping for $TIMEOUT seconds"
    sleep $TIMEOUT
done
