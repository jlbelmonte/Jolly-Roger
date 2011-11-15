#/bin/bash -x
VERSION='0.1'
CONNECTIVITY=0
LOG_FORMAT=' --format=COMMITLINEMARK%n{\"revision\":\"%H\",\"author\":\"%an\",\"comitter\":\"%cn\",\"timestamp\":\"%ct\",\"message\":\"%f\"} '
LOG_DEFAULT_OPTIONS=' --raw --stat --no-merges '
LOG_CMD='git log '

#Configuration Do not touch
get_last_revision (){
	revision=`git config --local --get masterbranch.lastrevision`
	echo $revision
}
get_user_name () {
	git_name=`git config --global --get user.name`
	if [[ -z $git_name ]]
	then
		$git_name=`users`
	fi
	echo "$git_name"
}
AUTHOR_OPTIONS=' --author="'$(get_user_name)'"'


test_connection(){
	ping -c 2 google.com
	if [[ 0 == $? ]]
	then
		CONNECTIVITY=1
	fi	
}

test_connection

if [[ $CONNECTIVITY == 1 ]]
then
	last_rev=$(get_last_revision)
	if [[ -z $last_rev ]]
	then
		LOG_COMMAND=${LOG_CMD}'-n 1'${LOG_DEFAULT_OPTIONS}${LOG_FORMAT}
	else
		LOG_COMMAND=$LOG_CMD$LOG_DEFAULT_OPTIONS$LOG_FORMAT$AUTHOR_OPTIONS$last_rev..HEAD
		git config --unset --local masterbranch.lastrevision
	fi
else
	last_rev=$(get_last_revision)
	if [[ -z $last_rev ]]
	then
		last_commit=`git log -n 1 --format=%H`
		git config --local --add masterbranch.lastrevision ${last_commit}
	fi
	exit 255
fi


#Git commands

#Masterbranch urls
LISTENERURL='http://localhost:9000/local-hook'



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



#User parameters
token=$(get_token)
repository_url=`git config --local --get remote.origin.url`
if [[ -z $repository_url ]]
then
	repository_url=${PWD##*/}
fi

raw_data=`$LOG_COMMAND` 
encoded_data=`echo -n $raw_data | openssl enc -e -base64 | tr -d "\n"`

url_params="repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  
echo $url_params
curl -d $url_params ${LISTENERURL} > result.out

