#!/bin/bash
tag_version="v1"
tag_sprint="1"
patch_prefix="-alpha"
branch_protected="develop"

makeSureInput() {
    echo "Are you sure ? [y/n]"
    read var
    if [ -z $var ]; then
        exit 0
    elif [ $var == "y" ]; then
        return
    else
        exit 0
    fi
}
currentVersion() {
    echo "Fetch tags"
    git fetch --prune --tags

    version=$(git tag -l "${tag_version}.${tag_sprint}.[0-9]${patch_prefix}.[0-9]*" --sort=-v:refname | head -n 1)
    
    if [ -z $version ]; then
        version='this first tag'
    fi

    echo "$(tput setaf 6)$(tput bold)Current version: $(tput setaf 4)$(tput bold)${version}$(tput sgr 0)"
    increment=(${version//./ })
}
checkIsMasterBranch() {
    current_branch=$(git branch | grep \* | cut -d ' ' -f2)
    if [ $current_branch != "${branch_protected}" ]
    then
        echo "Error: Your current branch is not supported for tag."
        exit 1
    fi
}
checkIsConflict() {
    CONFLICTS=$(git ls-files -u | wc -l)
    if [ "$CONFLICTS" -gt 0 ] ; then
        echo "Error: There is a merge conflict. Aborting generate tag"
        exit 1
    fi
}
checkIsCommitsBeyondRemoteOrigin() {
  IS_CURRENT_BRANCH_UP_TO_DATE=$(git log origin/"${branch_protected}..${branch_protected}")
  if [ -z "$IS_CURRENT_BRANCH_UP_TO_DATE" ];
  then
    return
  fi

  echo "Error: This branch has beyond commits"
  exit 1
}

if [ $# -eq 0 ]; then
    echo "$(tput setaf 1)$(tput bold)Please fill arguments [major/minor/patch]$(tput sgr 0)"
    exit 0
elif [ $1 == "major" ]; then
    echo "$(tput setaf 6)$(tput bold)Update tag version $(tput setaf 4)$(tput bold)x.x.x-alpha.x$(tput sgr 0)"
    currentVersion

    increment=(${increment/$tag_version/$tag_sprint/$patch_prefix/})
    increment=(${increment//./ })

    increment[0]=${tag_version}
    increment[1]=${tag_sprint}
    increment[2]=0${patch_prefix}
    increment[3]=0
elif [ $1 == "minor" ]; then
    echo "$(tput setaf 6)$(tput bold)Update tag version $(tput setaf 4)$(tput bold)x.x.minor-alpha.x$(tput sgr 0)"
    currentVersion
    ((increment[2]++))
    increment[2]=${increment[2]}${patch_prefix}
    increment[3]=0
elif [ $1 == "patch" ]; then
    echo "$(tput setaf 6)$(tput bold)Update tag version $(tput setaf 4)$(tput bold)x.x.x-alpha.patch$(tput sgr 0)"
    currentVersion
    ((increment[3]++))
else
    echo "$(tput setaf 1)$(tput bold)Please fill arguments [major/minor/patch]$(tput sgr 0)"
    exit 0
fi

set -e
checkIsMasterBranch
git pull origin "$branch_protected"
checkIsConflict
checkIsCommitsBeyondRemoteOrigin
git pull origin $(git branch | grep \* | cut -d ' ' -f2)
next_version="${increment[0]}.${increment[1]}.${increment[2]}.${increment[3]}"
msg="Update version $1 by $(git config user.name)"
echo "$(tput setaf 6)$(tput bold)Add new git tag $(tput setaf 4)$(tput bold)$next_version $(tput setaf 6)$(tput bold)with message: $(tput setaf 4)$(tput bold)$msg $(tput sgr 0)"
makeSureInput
git tag -a "$next_version" -m "$msg"
git push origin "$next_version"
echo "$(tput setaf 2)$(tput bold)Push tag success$(tput sgr 0)"