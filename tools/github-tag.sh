#!/bin/bash

# Fail on error
set -e

if [[ -z "${GIT_DEPLOY_KEY}" ]]; then
  echo "GIT_DEPLOY_KEY not set."
  exit 1
fi

# Setup git deploy key
install -m u=rwx,go= -d ~/.ssh
echo "${GIT_DEPLOY_KEY}" > ~/.ssh/agnosticd_deploy_key.id_rsa
chmod go= ~/.ssh/agnosticd_deploy_key.id_rsa
export GIT_SSH_COMMAND="ssh -i ~/.ssh/agnosticd_deploy_key.id_rsa -F /dev/null"

function die {
  echo "${1}" >&2
  exit 1
}

function check_tag_exists {
  TAG="${1}"
  COMMIT="$(git log --pretty=format:'%H' -n 1)"
  TAG_COMMIT="$(git log --pretty=format:'%H' -n 1 "${TAG}" 2>/dev/null)"

  if [[ -z "${TAG_COMMIT}" ]]; then
    return 1
  elif [[ "${COMMIT}" == "${TAG_COMMIT}" ]]; then
    return 0
  fi

  die "${TAG} commit mismatch ${COMMIT} != ${TAG_COMMIT}"
}

git log
git diff-tree --no-commit-id --name-only -r HEAD HEAD^

for FILE in "$(git diff-tree --no-commit-id --name-only -r HEAD HEAD^ | egrep '^ansible/configs/[a-zA-Z0-9_\-]+/releases/[a-zA-Z0-9_\-]+.txt$')"
do
  VERSION="$(tail -n1 ${FILE})"
  PREFIX="$(basename ${FILE} | sed 's/\.txt$//')"
  TAG="${PREFIX}-${VERSION}"
  if check_tag_exists "${TAG}"; then
    echo "${TAG} exists"
  else
    git tag "${TAG}"
  fi
  git push origin "${TAG}"
done

