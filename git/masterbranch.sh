#/bin/bash
VERSION='0.1'
#Masterbranch urls
LISTENERURL='http://localhost:9000/local-hook'
LOG_FORMAT=' --format=COMMITLINEMARK%n{\"revision\":\"%H\",\"author\":\"%an\",\"comitter\":\"%cn\",\"timestamp\":\"%ct\",\"message\":\"%f\"} '
LOG_DEFAULT_OPTIONS=' --raw --stat --no-merges '
LOG_CMD='git log '

#Configuration Do not touch
get_last_revision_pushed_to_mb (){
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
	if [[ 0 != $? ]]
	then
		exit 42
	fi	
}

test_connection


last_rev=$(get_last_revision_pushed_to_mb)
if [[ -z $last_rev ]]
then
	rev_array=(`git log -n2 --format=%H`)
	last_rev=${rev_array[1]}
fi

LOG_COMMAND=$LOG_CMD$LOG_DEFAULT_OPTIONS$LOG_FORMAT$AUTHOR_OPTIONS$last_rev..HEAD
print_error () {
	echo Please config your client as follows
		echo git config --global --add masterbranch.token YOURTOKEN
		echo git config --global --add masterbranch.token YOURTOKEN
		exit 255
}

get_token () {
	masterbranch_token=`git config  --global --get masterbranch.token`
	if [[ -z $masterbranch_token ]]
	then
		print_error
	fi	
	echo "$masterbranch_token"	
}

get_email () {
	masterbranch_email=`git config  --global --get masterbranch.email`
	if [[ -z $masterbranch_email ]]
	then
		print_error
	fi	
	echo "$masterbranch_email"		
}

get_repository () {
	uri=`git config --local --get remote.origin.url`
	if [[ -z $uri ]]
	then
		uri=${PWD##*/}
	fi
	echo "$uri"
}


token=$(get_token)
email=$(get_email)
repository_url=$(get_repository) 

raw_data=`$LOG_COMMAND` 
encoded_data=`echo -n $raw_data | openssl enc -e -base64 | tr -d "\n"`

url_params="repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  
curl -d $url_params ${LISTENERURL} 

#keeping track of revisions already pushed to masterbranch.com
if($?)
then
	actual=`git log -n 1 --format=%H`
	git --local --unset masterbranch.lastrevision
	git config --local --add masterbranch.lastrevision ${actual}
fi

