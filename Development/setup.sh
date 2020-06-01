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
		echo "    ! Unable to find '$1'"
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
	"modprobe" 
	"more" 
	"mv" 
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
echo "  . All required command line utilities found"

echo
echo "- Learning apache server configuration"

# find apache user
echo "  - Detecting apache user"
apache_user=$(apachectl -S 2>&1 | sed -r -n 's/^User:\sname=\"(.*)\"\s*id=[[:digit:]]*$/\1/p') || exit 1
if [ ! -z "$apache_user" ]
then
	echo "    = $apache_user"  
else
	echo "    ! Unable to identify apache user"
	exit 99
fi

# locate target directory for apache files
echo "  - Detecting apache document root"
web_dir=$(apachectl -S 2>&1 | sed -r -n 's/^Main\sDocumentRoot:\s\"(.*)\"/\1/p')
if [ ! -z "$web_dir" ]
then
	echo "    = $web_dir"  
else
	echo "    ! Unable to identify apache Main DocumentRoot"
	exit 99
fi

echo "  . Apache server detection complete"


# checkdir function to verify directory is present and writable
do_checkdir () {
# parameter is directory
	local dir=$1
	if [ -d "$1" ] 
	then
		if [ ! -w "$1" ] 
		then
			echo "  ! $1/ not writable"
		fi
	else
		echo "  ! Unable to find $1/"
		exit 99
	fi
}


# define target directory for application scripts
# TODO: make this adjustable
script_install_dir="/root"

# write sudoers file 
echo
echo "- Configuring sudo"
sudoers_dir="/etc/sudoers.d"
sudoers_file="$sudoers_dir/20_wanem_user"
do_checkdir $sudoers_dir
if [ -f "$sudoers_file" ] && [ ! -w "$sudoers_file" ]
then
	echo "  ! File $sudoers_file already exists and is not writeable"
	exit 99
fi
cat > "$sudoers_file" <<_SUDOERS_END
# Give detected apache user rights for wanem required scripts and utilities
%$apache_user         ALL=NOPASSWD:$tc_loc, $echo_loc, $mv_loc, $grep_loc, $conntrack_loc, $script_install_dir/disc_new_port_int/disconnect.sh, $script_install_dir/disc_new_port_int/check_disco.sh, $script_install_dir/disc_new_port_int/reset_disc.sh, $script_install_dir/wanalyzer/tcs_wanc_menu.sh, $script_install_dir/wanalyzer/tcs_wanem_main.sh
_SUDOERS_END
echo "  . Configured $sudoers_file"
 
# install web content
echo
echo "- Processing web content"
do_checkdir $web_dir
cd web_home
# make a list of content without that pesky ./
for f in $(find -print0 | xargs -0 -n1 | cut -c 3-)
do
	echo "  - Installing $f"
    if [ -d "./$f" ] 
	then
    	if [ -d "$web_dir/$f" ] 
		then
			if [ ! -w "$web_dir/$f" ] 
			then
				echo "  ! $web_dir/ is not writable"
				exit 99
			fi
		else
			if [ ! -w "$web_dir/$f/.." ]
			then
				echo "  ! Parent directory of $web_dir/$f is not writable"
				exit 99
			fi
			mkdir "$web_dir/$f"	
		fi
	else
		if [ -f "$web_dir/$f" ] && [ ! -w "$web_dir/$f" ]
		then
			echo "  ! $webdir/$f is read only"
			exit 99
		fi
		cp "./$f" "$web_dir/"
	fi
done
cd ..
echo "  . Web content complete"

# install script content
echo
echo "- Processing script content"
do_checkdir $script_install_dir
cd root_home
# make a list of content without that pesky ./
for f in $(find -print0 | xargs -0 -n1 | cut -c 3-)
do
	echo "  - Installing $f"
    if [ -d "./$f" ] 
	then
       	if [ -d "$script_install_dir/$f" ] 
		then
			if [ ! -w "$script_install_dir/$f" ] 
			then
				echo "  ! $script_install_dir/ not writable"
				exit 99
			fi
		else
			if [ ! -w "$script_install_dir/$f/.." ]
			then
				echo "  ! Parent directory of $script_install_dir/$f is not writable"
				exit 99
			fi
			mkdir "$script_install_dir/$f"	
		fi
	else
		if [ -f "$script_install_dir/$f" ] && [ ! -w "$script_install_dir/$f" ]
		then
			echo "  ! $script_install_dir/$f is read only"
			exit 99
		fi
		cp "./$f" "$script_install_dir/"
	fi
done
cd ..
echo "  . Script content complete"

echo
echo "Setup complete."
