#!/bin/bash
# trap any exit code.  99 means kill the whole script.
set -E
trap '[ "$?" -ne 99 ] || exit 99' ERR

# verify running as root 
if [[ $EUID > 0 ]]
	then
		echo "ERROR: Run setup script as root"
		exit 99 
	else
		echo "Initiating setup process" 
		echo
fi

# locate function 
do_locate () {
# parameter is program to locate
# return is global variable named *programname*_loc
	local __resultvar="$1_loc"
	echo "  - Locating $1"
	eval $__resultvar="'$(which $1)'"
	if [ ! -z $( eval "echo \$$__resultvar" ) ]
	then
		echo -ne "    = "
		echo $( eval "echo \$$__resultvar" )
		declare -x $__resultvar
	else
		echo "    ! Unable to find '$1'."
		exit 99
	fi
}

echo
# locate command line utilites we'll need to complete setup and operate correctly
echo "- Finding relevant command line utilities"
required_utils=(
	"apachectl" 
	"awk" 
	"brctl" 
	"cat" 
	"chmod" 
	"chown" 
	"chgrp" 
	"conntrack" 
	"cut" 
	"echo" 
	"find" 
	"grep" 
	"ifconfig" 
	"iptables" 
	"killall" 
	"mv" 
	"more" 
	"nmcli" 
	"pgrep" 
	"ping" 
	"php" 
	"pump" 
	"route" 
	"sed" 
	"sleep" 
	"sudo" 
	"tail" 
	"tc" 
	"touch" 
	"xargs" 
	"wc"
)
for u in "${required_utils[@]}"
do
	do_locate $u
done

echo
echo "- Learning apache server configuration"

# find apache user
echo "  - Detecting apache user"
apache_user=$(apachectl -S 2>&1 | sed -r -n 's/^User:\sname=\"(.*)\"\s*id=[[:digit:]]*$/\1/p') || exit 1
if [ ! -z "$apache_user" ]
then
	echo "    = $apache_user"  
else
	echo "    ! Unable to identify apache user."
	exit 99
fi

# locate target directory for apache files
echo "  - Detecting apache document root"
target_dir=$(apachectl -S 2>&1 | sed -r -n 's/^Main\sDocumentRoot:\s\"(.*)\"/\1/p')
if [ ! -z "$target_dir" ]
then
	echo "    = $target_dir"  
else
	echo "    ! Unable to identify apache Main DocumentRoot."
	exit 99
fi



# define target directory for application scripts
# TODO: make this adjustable
script_install_dir="/root"

# write sudoers file 
echo
echo "- Configuring sudo"
#php -r 'echo preg_replace_callback("/\\$([a-z0-9_]+)/i", function ($matches) { return getenv($matches[1]); }, fread(STDIN, 8192));' < ./config_templates/20_wanem_user.template > /etc/sudoers.d/20_wanem_user
cat ./config_templates/20_wanem_user.template | envsubst > /tmp/20_wanem_user
echo > "/tmp/20_wanem_user"
while read line 
do
    line=${line/\$script_install_dir\}/$script_install_dir}
	echo "$line" >> "/tmp/20_wanem_user"
done < "./config_templates/20_wanem_user.template"
cat ./config_templates/20_wanem_user.template | envsubst > /tmp/20_wanem_user
cat <<_SUDOERS_END
# Give detected apache user rights for wanem required scripts and utilities
%$apache_user         ALL=NOPASSWD:$tc_loc, $echo_loc, $mv_loc, $grep_loc, $conntrack_loc, $script_install_dir/disc_new_port_int/disconnect.sh, $script_install_dir/disc_new_port_int/check_disco.sh, $script_install_dir/disc_new_port_int/reset_disc.sh, $script_install_dir/wanalyzer/tcs_wanc_menu.sh, $script_install_dir/wanalyzer/tcs_wanem_main.sh
_SUDOERS_END
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
