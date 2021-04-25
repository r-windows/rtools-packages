#!/bin/bash
cd "$(dirname "$0")"
source 'ci-library.sh'
mkdir artifacts
cd artifacts
echo "REMOVING PACKAGE ${PACKAGE} from ${PACMAN_REPOSITORY}"
execute 'Updating package index' remove_from_repository "${PACMAN_REPOSITORY}" "${PACKAGE}"
success 'Package removal successful'
exit 0
