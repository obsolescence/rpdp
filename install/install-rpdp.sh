#!/bin/bash
#
#
# install script for PiDP-10 rpdp remote terminals
# v0.20240430
#

# check this script is NOT run as root
if [ "$(whoami)" == "root" ]; then
    echo script must NOT be run as root
    exit 1
fi

if [ ! -d "/opt/rpdp" ]; then
    echo clone git repo into /opt/
    exit 1
fi

echo
echo
echo PiDP-10 rpdp install script
echo ======================
echo
echo
echo INSTALL TERMINAL SIMULATORS FOR REMOTE PiDP-10 CONNECTIONS
echo
echo
echo This script is minimally invasive to your Linux. 
echo All it does outside echo its own directory is, if you allow, 
echo make a link in \/usr\/bin.
echo
echo It does install quite a lot of regular ilibrary packages.
echo
echo Re-running the script and answering \'n\' to questions
echo will leave those things unchanged. So it will *not* undo anything
echo that is already installed.
echo 
echo
echo For Linux, but will work under Windows 11 with WSL installed too
echo

read -p "Set required access privileges to rpdp directory? " yn
case $yn in
    [Yy]* )
	    # make sure that the directory does not have root ownership
	    # (in case the user did a simple git clone instead of 
	    #  sudo -u pi git clone...)
	    myusername=$(whoami)
	    mygroup=$(id -g -n)
	    sudo chown -R $myusername:$mygroup /opt/rpdp
        echo "...Done."
	    ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac
echo
#
# ---------------------------
# Determine architecture & create bin dir
# ---------------------------
read -p "Create rpdp/bin directory with right binaries for your computer? " yn
case $yn in
    [Yy]* ) 
        echo "Determining architecture (X86 or Pi)..."
        if [ "$(uname -m)" == "x86_64" ]; then
            archi="intel"
        elif [ "$(uname -m)" == "aarch64" ]; then
            archi="pi64"
        else
            echo "Did not recognize either X86_64 (PC) or aarch64 (Raspberry Pi)"
            echo "Stopping install - no suitable binaries"
            echo "You could compile from source though."
            exit 1
        fi
        echo "...Done."
        echo
        echo "Creating and copying files to \/opt\/rpdp\/bin directory..."
        if [ -d "/opt/rpdp/bin" ]; then
            rm -rf "/opt/rpdp/bin"
        fi
        mkdir /opt/rpdp/bin
        cp /opt/rpdp/store-$archi/* /opt/rpdp/bin
        echo "...Done."
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Copy control scripts (pdpcontrol, pdp) to /usr/local/bin?
# ---------------------------
read -p "Copy control script link (rpdp) to /usr/local/bin? " yn
case $yn in
    [Yy]* ) 
	    sudo ln -i -s /opt/rpdp/bin/rpdp.sh /usr/local/bin/rpdp
        echo "...Done."
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Install required dependencies
# ---------------------------
read -p "Install required dependencies for running the terminal sims? " yn
case $yn in
    [Yy]* ) 
        # update first...
        sudo apt-get update
        # for simh:
	sudo apt install -y libpcre3
        sudo apt install -y libsdl2-image-dev
        sudo apt install -y libsdl2-net-dev
	sudo apt install -y libvdeplug2
	sudo apt install -y libpcap-dev
	#Most systems do not come with telnet installed, so --
        sudo apt-get install -y telnet
        #sudo apt-get install -y telnetd
	# for pdpcontrol: 
	#sudo apt-get -y install expect
        # Install screen
        #sudo apt-get install -y screen
	# Install Tilix, used for pdp view
	#sudo apt -y install tilix
    #sudo apt -y install dconf-editor dconf-cli
    #dconf load /com/gexperts/Tilix/ </opt/pidp10/install/pidp10tilix.conf
        echo "...Done."
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Modify rpdp.sh and simlac.simh with right hostname and user name
# ---------------------------
read -p "Modify config files with correct hostname and user name? " yn
case $yn in
    [Yy]* ) 
        while true; do
            echo -----------------------
            read -p "Hostname of the PiDP-10 ?  " hostnm
            read -p "User name on the PiDP-10 ? " usernm
            echo "OK. Host name is $hostnm and user name is $usernm"
            echo -----------------------
            read -p "Correct? (y/n) ? " ynnm
            if [[ "$ynnm" == "Y" || "$ynnm" == "y" ]]; then
                break;
            fi
        done
        echo "...Done."
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac
sed -i "s/^pidpremote=.*/pidpremote=\"$hostnm.local\"/" "/opt/rpdp/bin/rpdp.sh"
sed -i "s/^piuser=.*/piuser=\"$usernm\"/" "/opt/rpdp/bin/rpdp.sh"
sed -i "s/attach -u tty 12345,connect=.*.local:10003;notelnet/attach -u tty 12345,connect=$hostnm.local:10003;notelnet/" /opt/rpdp/bin/imlac.simh
echo "...Done."

