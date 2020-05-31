#!/bin/bash

# verify running as root 
if [[ $EUID > 0 ]]
	then
		echo "ERROR: Run setup script as root"
		exit 1 
	else
		echo "Initiating setup process" 
		echo
fi


# find apache user
echo "- Detecting apache user"
apache_user=$(apachectl -S 2>&1 | sed -r -n 's/^User:\sname=(.*)\s*id=[[:digit:]]*$/\1/p') || exit 1
if [ ! -z "$apache_user" ]
then
	echo "  - Found: $apache_user"  
else
	echo "  ! Unable to identify apache user. Is 'apachectl' available and on the path?"
	exit 1
fi

# locate target directory for apache files
echo "- Detecting apache document root"
target_dir=$(apachectl -S 2>&1 | sed -n 's/^Main DocumentRoot: //p')
if [ ! -z "$target_dir" ]
then
	echo "  - Found: $target_dir"  
else
	echo "  ! Unable to identify apache Main DocumentRoot."
	exit 1
fi

# locate function 
do_locate () {
# first parameter is program to locate
# second parameter is global variable to get resulting path
	local __resultvar=$2
	echo "- Locating $1"
	if [ ! -z "'$(which $1)'" ]
	then
		eval $__resultvar="'$(which $1)'"
	else
		echo "  ! Unable to find '$1'."
		exit 1
	fi
}

# locate programs we'll need to complete our setup
do_locate apachectl dontcare_loc
do_locate awk dontcare_loc
do_locate brctl dontcare_loc
do_locate cat dontcare_loc
do_locate chmod dontcare_loc
do_locate chown dontcare_loc
do_locate chgrp dontcare_loc
do_locate conntrack conntrack_loc
do_locate cut dontcare_loc
do_locate echo echo_loc
do_locate find dontcare_loc
do_locate grep grep_loc
do_locate ifconfig dontcare_loc 
do_locate iptables dontcare_loc 
do_locate killall dontcare_loc 
do_locate mv mv_loc
do_locate more dontcare_loc
do_locate nmcli nmcli_loc
do_locate pgrep dontcare_loc
do_locate ping dontcare_loc
do_locate pump dontcare_loc
do_locate route dontcare_loc
do_locate sed dontcare_loc
do_locate sleep dontcare_loc
do_locate sudo dontcare_loc
do_locate tail dontcare_loc
do_locate tc tc_loc
do_locate touch dontcare_loc
do_locate xargs dontcare_loc
do_locate wc dontcare_loc

# define target directory for application scripts
# TODO: make this adjustable
script_install_dir="/root"

# write sudoers file 
echo
echo "- Configuring sudo"
exit
 
# install web content
echo
echo "- Processing web content"
cd web_home
# make a list of content without that pesky ./
for f in $(find -print0 | xargs -0 -n1 | cut -c 3-)
do
	echo "  - Installing $f"
        if [ -d "./$f" ] 
	then
        	if [ ! -d "$target_dir/$f" ] 
		then
			mkdir "$target_dir/$f"	
		fi
	else
		cp "./$f" "$target_dir/"
	fi
done
cd ..
echo "  - Web content complete"

# install script content
echo
echo "- Processing script content"
cd root_home
target_dir="/root"
# make a list of content without that pesky ./
for f in $(find -print0 | xargs -0 -n1 | cut -c 3-)
do
	echo "  - Installing $f"
        if [ -d "./$f" ] 
	then
        	if [ ! -d "$target_dir/$f" ] 
		then
			mkdir "$target_dir/$f"	
		fi
	else
		cp "./$f" "$target_dir/"
	fi
done
cd ..
echo "  - Script content complete"

echo
echo "Setup complete"
