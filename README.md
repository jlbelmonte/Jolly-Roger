**Version 0.1**

Git hook setup

Under the git directory you'll find the masterbranch post-commit script.

    
* Git global configuration.

Your private token is under Settings -> Account admin
[Token section](http://mb-misc.s3.amazonaws.com/token.png)

	git config --global --add masterbranch.token TOKEN
	git config --global --add masterbranch.email EMAIL

	
*Project configuration.

For each project yo would like to  push to masterbranch you need to activate your post-commit hook.
		
	Download the git masterbranch hook script
	Place it under /path/to/your/project/.git/hooks
		
	cd /path/to/your/project/.git/hooks
	chmod +x masterbranch 

	mv post-commit.sample post-commit
	echo ${PWD}/masterbranch >> post-commit



