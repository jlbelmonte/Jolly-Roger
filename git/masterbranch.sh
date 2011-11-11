#/bin/bash -x
VERSION='0.1'

#Configuration Do not touch
#Git commands
CMD="curl -s -d repotoken=${REPOSITORY_TOKEN}"
LOG_COMMAND="git log --format=COMMITLINEMARK%n{\"revision\":\"%H\",\"author\":\"%an\",\"comitter\":\"%cn\",\"timestamp\":\"%ct\",\"message\":\"%f\"} --raw --stat --no-merges --author=${AUTHOR}"

#Masterbranch urls
BASE_URL='http://localhost:9000/'
LISTENER_CONTROLLER='local-hook'
LISTENERURL=${BASE_URL}${LISTENER_CONTROLLER}


get_user_name () {
	git_name=`git config --global --get user.name`
	if [[ -z $git_name ]]
	then
		$git_name=`users`
	fi
	echo "$git_name"
}

get_token () {
	masterbranch_token=`git config  --global --get masterbranch.token`
	if [[ -z $masterbranch_token ]]
	then
		echo Please config your client as follows
		echo git config --global --add masterbranch.token YOURTOKEN
		exit 255
	fi	
	echo "$masterbranch_token"	
}

get_last_revision (){
	revision=`git config --local --get masterbranch.lastrevision`
	if [[ -z $revision ]]
	then
		revision=0
	fi
	echo $revision
}

#User parameters
token=$(get_token)
user=$(get_user_name)
repository_url=`git config --local --get remote.origin.url`
last_revision=$(get_last_revision)

#Commit process


if [[ ${last_revision} == 0 ]]
then
	raw_data=`$LOG_COMMAND`  
else
	raw_data=`$LOG_COMMAND ${last_commit}..HEAD`
fi


curl -d "token=${TOKEN}&payload=${raw_data}&version=${VERSION}" ${LISTENERURL} > /dev/null 2>&1

