#!/bin/bash

if [ ! -f fdroid/repo/index-v1.json ]; then
	echo "Initializing F-Droid repository"
	cd fdroid

	# Создаем базовую структуру
	mkdir -p repo metadata

	# Создаем пустые метаданные и запускаем fdroid update
	fdroid update --create-metadata --pretty

	cd ..
fi

cd metascoop
echo "::group::Building metascoop executable"
go build -o metascoop
echo "::endgroup::"

./metascoop -ap=../apps.yaml -rd=../fdroid/repo -pat="$GH_ACCESS_TOKEN" "$1"
EXIT_CODE=$?
cd ..

echo "Scoop had an exit code of $EXIT_CODE"

set -e

if [ $EXIT_CODE -eq 2 ]; then
	# Exit code 2 means that there were no significant changes
	echo "This means that there were no significant changes"
	exit 0
elif [ $EXIT_CODE -eq 0 ]; then
	# Exit code 0 means that we can commit everything & push

	echo "This means that we now have changes we should push"

	echo "Configuring git for large repository"
	git config --global http.postBuffer 524288000
	git config --global http.maxRequestBuffer 524288000
	git config --global core.compression 0

	git gc --aggressive
	git fsck

	git config --global user.name 'github-actions'
	git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'

	git add .
	git commit -m "Automated update"
	git push
else
	echo "This is an unexpected error"

	exit $EXIT_CODE
fi
