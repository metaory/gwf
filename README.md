GitHub Work Flow
================

SETUP
-----
[github access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
```
export GITHUB_ACCESS_TOKEN=github_access_token
```
```
REPO="<repository>"
OWNER="<owner>"
PACKAGE_JSON="<package.json relative path>"
PROD_BRANCH="<production branch name>"
STAGE_BRANCH="<staging branch name>"
```
***

RUN
---
```
bash release.sh
```
or
```
yarn release
```
***

### What it does?
+ reads **version** from `package.json`
+ collects `TAG NAME`, `RELEASE TITLE`, `RELEASE BODY`, `DRAFT RELEASE`, `PRE RELEASE`, 
with default values from **version** and **git logs**
+ tag
+ merge `STAGE` into `PROD`
+ push everything
+ create github release
