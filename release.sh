#!/bin/bash

VERSION=$(cat ./package.json  | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g')
VERSION=${VERSION#" "}
RELEASE_DATE=`date +%b-%d`
ENV="PRODUCTION"
OWNER="metaory"
REPO="gwf"

bold=$(tput bold)
normal="\033[0m"
red="\033[1;31m"
blue="\033[1;34m"
green="\033[1;32m"
yellow="\033[1;33m"
grey="\033[1;30m"

# ############################################################################ #

log () {
    case "${1}" in
        -1) level="[${red}ERROR${normal}]";;
        0)  level="[${blue}INFO${normal}]";;
        1)  level="[${yellow}WARNING${normal}]";;
    esac
    printf "${normal}$level $2 ${normal}\n"
}

# ############################################################################ #

log 0 "${bold}FETCHING ${red}origin ${normal}${bold}..."
git fetch origin
GIT_LOG=$(git shortlog origin/production..origin/stage)
GIT_COMMIT_COUNT=$(git log --oneline origin/stage ^origin/production | wc -l)
GIT_DIFF_STAT=$(git diff --shortstat origin/production..origin/stage)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_CONTRIB_COUNT=$(git shortlog -sn)

if [ -z $GIT_ACCESS_TOKEN ]; then
  log -1 "${bold}export GIT_ACCESS_TOKEN='<github_access_token>'"
  exit
fi

# ############################################################################ #

prompt_commit_summary () {
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}VIEW COMMIT SUMMARY? [y/N]${normal} "
    read -r  view_commit_summary
    if [[ "$view_commit_summary" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all origin/production..origin/stage
    fi
}

# ############################################################################ #

collect () {
    # ############################################################################ #
    # ## TAG NAME ################################################################ #
    # ############################################################################ #
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}TAG NAME? ${grey}(v$VERSION)${red} "
    read -r  tag_name
    tag_name=${tag_name:-"v$VERSION"}
    log 0 "${bold}TAG NAME:  ${red}${tag_name}"
    log 0 "${bold}SEARCHING REMOTE FOR TAG NAME ${red}${tag_name} ${normal}${bold}..."
    if [ $(git ls-remote --tags origin | grep -c $tag_name) -ne 0 ]; then
      log -1 "${bold}${red}TAG ${tag_name} EXISTS "
      exit
    fi
    # ############################################################################ #
    # ## DRAFT RELEASE ########################################################### #
    # ############################################################################ #
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}DRAFT RELEASE? [y/N]${red} "
    read -r  draft_release
    if [[ "$draft_release" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        draft_release="true"
    else
        draft_release="false"
    fi
    log 0 "${bold}DRAFT RELEASE: ${red}${draft_release}"
    # ############################################################################ #
    # ## PRE RELEASE ############################################################# #
    # ############################################################################ #
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}PRE RELEASE? [y/N]${red} "
    read -r  pre_release
    if [[ "$pre_release" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        pre_release="true"
    else
        pre_release="false"
    fi
    log 0 "${bold}PRE RELEASE: ${red}${pre_release}"
    # ############################################################################ #
    # ## RELEASE TITLE ########################################################### #
    # ############################################################################ #
    default_release_title="$tag_name $RELEASE_DATE"
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}RELEASE TITLE? ${grey}($default_release_title)${red} "
    read -r  release_title
    release_title=${release_title:-"$default_release_title"}
    log 0 "${bold}RELEASE TITLE: ${red}${release_title}"
    # ############################################################################ #
    # ## RELEASE BODY ############################################################ #
    # ############################################################################ #
    default_release_desc="v$version $RELEASE_DATE #$GIT_COMMIT_COUNT"
    release_body=$(git log --pretty=format:"[%an] %s" --date=short origin/production..origin/stage)
    printf "${normal}[${blue}INFO${normal}] ${bold}${yellow}RELEASE BODY:${normal}\n"
    printf "${bold}${release_body}\n"

    printf "${normal}[${blue}INFO${normal}] ${bold}${red}RELEASE? [y/N] "
    read -r  release
    if [[ "$release" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
      release
    else
      exit
    fi
}

# ############################################################################ #


release () {
    log 0 "${bold}RELEASING ${red}${release_title} ${normal}${bold}..."
    git checkout stage
    git pull origin stage
    git commit -am "$release_title"
    git push origin stage
    git checkout -f production
    git pull origin production
    git merge origin/stage -m "$release_title"
    git tag $tag_name
    git push origin production
    git push --tags
    sleep 5
    release_body="${release_body//$'\n'/<br/>}"
    curl -i \
    -H "Content-Type:application/json" \
    -X POST https://api.github.com/repos/$OWNER/$REPO/releases\?access_token\=$GIT_ACCESS_TOKEN \
    -d @- << EOF
{
    "tag_name": "$tag_name",
    "target_commitish": "stage",
    "name": "$release_title",
    "body": "$release_body",
    "draft": $draft_release,
    "prerelease": $pre_release
}
EOF
    git checkout stage
}

prompt_commit_summary
collect
