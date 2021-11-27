#!/usr/bin/bash

####
# Small script to retrieve last version
# Increase version based on semver rules and conventional commits
# Then tag sources and push that to remote
# 
# When combined with pipeline triggers on commit will allow you to quickly create a release
###

# retrieve latest version from tags
git fetch --all --tags
tag=`git describe --abbrev=0`

echo "Check changes since $tag"

# split tag string into its semver parts
IFS='.'
read -ra ADDR <<< "$tag"
major=${ADDR[0]}
minor=${ADDR[1]}
patch=${ADDR[2]}

# detect semantic version increase by conventional commits
type="none"

if git log "$tag"..HEAD --format="%s" | grep -v "docs:"; then
    type="patch"
fi

if git log "$tag"..HEAD --format="%s" | grep "feat:"; then
    type="minor"
fi

if git log "$tag"..HEAD --format="%s" | grep "!:"; then
    type="major"
fi

if git log "$tag"..HEAD --format="%s" | grep "BREAKING CHANGE:"; then
    type="major"
fi

# increase version as detected
if [ $type = "major" ] 
then
    major=$((major + 1))
    minor=0
    patch=0
fi

if [ $type = "minor" ] 
then
    minor=$((minor + 1))
    patch=0
fi

if [ $type = "patch" ] 
then
    patch=$((patch + 1))
fi

# format tag according to semver guidelines
new_tag="$major.$minor.$patch"

#check if any changes and if so release
if [ "$tag" != "$new_tag" ]; then
    echo "releasing version: $new_tag"
    git tag -a "$new_tag" -m "$new_tag $1"
    git push origin "$new_tag"
else 
    echo "no changes to release"
fi
