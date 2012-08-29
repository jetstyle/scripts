#!/bin/bash


SRC=$1
DST=$2
GIT_ACCOUNT=jetstyle

if [ -z "$SRC" ]; then
    echo "Usage: $0 SRC_SVN_REPO_NAME DST_GIT_REPO_NAME"
    exit 1;
fi

SVN_URL=svn://svn.$GIT_ACCOUNT.ru/$SRC

# detect branches and tags
BRANCHES=`svn ls $SVN_URL | grep branch | tr -d "/"`
#echo svn ls $SVN_URL | grep branch | tr -d "/"
TAGS=`svn ls $SVN_URL | grep tag | tr -d "/"`

# checkout cmd
cmd="git svn clone $SVN_URL -T trunk"

if [ $BRANCHES ]; then
   cmd="${cmd} -b $BRANCHES"
fi

if [ $TAGS ]; then
   cmd="${cmd} -t $TAGS"
fi

cmd="${cmd} ${SRC}"
echo $cmd

`$cmd`

# extract externals
CORE=`svn pg svn:externals ${SVN_URL}/trunk | grep core`

CORE_PATH=`echo $CORE | cut -d " " -f1 `

CORE_TAG=`echo $CORE | cut -d " " -f2 | cut -d "/" -f5 `
CORE_TAG="${CORE_TAG}/"`echo $CORE | cut -d " " -f2 | cut -d "/" -f6 `

echo $CORE_TAG
#exit

# tags be tags
if [ $TAGS ]; then 
    cp -Rf .git/refs/remotes/tags/* .git/refs/tags/
    rm -Rf .git/refs/remotes/tags
fi

# branches be branches
if [ $BRANCHES ]; then
    cp -Rf .git/refs/remotes/* .git/refs/heads/
    rm -Rf .git/refs/remotes
fi

cd $SRC

# TODO: get tags from svn pg svn:externals .
if [ $CORE_TAG ]; then
    make_submodules_cmd="git submodule add -b $CORE_TAG git@github.com:$GIT_ACCOUNT/core $CORE_PATH"
    #echo "Do manually:"
    echo $make_submodules_cmd
    `$make_submodules_cmd`
fi


# gitignore
echo "config/config.yml" >> .gitignore
echo "files/*" >> .gitignore
echo "cache/*" >> .gitignore
git add .gitignore

# make config be sample
mv config/config.yml config/config.yml.sample

echo "# Init core" >> scripts/init.sh
echo "git submodule init" >> scripts/init.sh
echo "git submodule update" >> scripts/init.sh
echo "cd core" >> scripts/init.sh

if [ $CORE_TAG ]; then
    echo "git checkout $CORE_TAG" >> scripts/init.sh
fi

# push to github
if [ $DST ]; then
    git commit -am "+ svn cloned"
    git remote add origin "git@github.com:$GIT_ACCOUNT/$DST.git"
    git push -u origin master

    echo "---------------------------------------------------------------------------------"
    echo "Go to http://github.com/$GIT_ACCOUNT/$DST/admin  to add teams and hooks"
    echo "http://jetbot.d.jetstyle.ru/gitup.php" 

    echo "---------------------------------------------------------------------------------"
    echo "Also shutdown $SVN_URL and http://$SRC.dev.jetstyle.ru"

    echo "---------------------------------------------------------------------------------"
    echo "Also deploy manually on hosting with: git clone git@github.com:jetstyle/$DST.git "
fi
