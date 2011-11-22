#/bin/sh
VERSION='0.1'
LISTENERURL='http://localhooks.masterbranch.com/local-hook'



get_last_revision_pushed_to_mb (){
	revision=`git config --local --get masterbranch.lastrevision`
}

get_user_name () {
	git_name=`git config --global --get user.name`
	if [ -z "$git_name" ]
	then
		git_name=`id | perl -ne 'm/uid=\d+\((\w+)\).*/; print "$1\n" '`
	fi
}

test_connection(){
	ping -c 2 google.com > /dev/null
	if [ 0 != $? ]
	then
		exit 42
	fi	
}

print_error () {
	echo Please config your client as follows
	echo git config --global --add masterbranch.token TOKEN
	echo git config --global --add masterbranch.email EMAIL
	exit 255
}

get_token () {
	masterbranch_token=`git config  --global --get masterbranch.token`
	if [ $masterbranch_token == "" ]
	then
		print_error
	fi	
	echo "$masterbranch_token"	
}

get_email () {
	masterbranch_email=`git config  --global --get masterbranch.email`
	if [ $masterbranch_email == "" ]
	then
		print_error
	fi	
	echo "$masterbranch_email"		
}

get_repository () {
	uri=`git config --local --get remote.origin.url`
	if [ $uri == "" ]
	then
		uri=${PWD##*/}
	fi
	echo "$uri"
}

do_log () {
	get_user_name
	# Notice than the commit parser just parses this format
	raw_data=`git log --author="$git_name" --pretty=format:'COMMITLINEMARK%n{ \"revision\": \"%H\",  \"author\": \"%an <%ae>\",  \"timestamp\": \"%ct\",  \"message\": \"%s\"}' --raw  $last_rev..HEAD`
}

set_last_revision () {
	last_rev=$(get_last_revision_pushed_to_mb)
	if [ -z $last_rev ]
	then
		last_rev=`git log -n2 --format=%H | tr "\n" ":" | perl -ne '@revs=split(/:/, $_); print @revs[1]'`
	fi
}

test_connection

get_token
token=$masterbranch_token 
get_email
email=$masterbranch_email
get_repository
repository_url=uri 
set_last_revision


do_log 
if [ -z "$raw_data" ]; then
	exit 0
fi

#Regular Base64 uses + and / for code point 62 and 63. URL-Safe Base64 uses - and _ instead. Also, URL-Safe base64 omits the == padding to help preserve space.
#http://en.wikipedia.org/wiki/Base64#URL_applications
encoded_data=`echo -n $raw_data | openssl enc -base64 | tr -d "\n" | tr "+" "-" | tr "/" "_" |tr -d "="` 

url_params="email=$email&vcs=git&repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  
#curl -d $url_params ${LISTENERURL} 
echo $url_params ${LISTENERURL}
#keeping track of revisions already pushed to masterbranch.com
if [ $? -eq "0" ]
then
	actual=`git log -n 1 --format=%H`
	get_last_revision_pushed_to_mb
	if [ -z $revision ]
	then
		git config --local --unset-all masterbranch.lastrevision
	fi
	git config --local --add masterbranch.lastrevision $actual
fi

