#!/bin/sh

RED='\033[0;31m';
NC='\033[0m';

ID=$(whoami);
GO_INSTALLED=$(command -v go 2> /dev/null);

install_go() {
	if [ ! $GO_INSTALLED = "" ]; then
            	echo "Go is already installed."
                return
        fi

	echo -e "\n${RED} [!] Go is not installed. Proceed to install...${NC}\n"
	url="https://golang.org/dl/$1"
	wget "${url}";
	echo -e "$RED""[!] Download successful : $url""$NC";
	tar -C /usr/local -xzf $1
	mkdir $HOME/go;
	export GOROOT=/usr/local/go;
	export GOPATH=$HOME/go;
	export PATH=$PATH:$GOROOT/bin:$GOPATH/bin;
	echo "export GOROOT=/usr/local/go" >> "$HOME"/.profile;
	echo "export GOPATH=$HOME/go" >> "$HOME"/.profile;
	echo "export PATH=$PATH:$GOROOT/bin:$GOPATH/bin" >> "$HOME"/.profile;
}

# Download latest Golang shell script
# https://gist.github.com/n8henrie/1043443463a4a511acf98aaa4f8f0f69
install_vuls() {
	echo -e "$RED""go-cve-dictionary + goval-dictionary installing...""$NC";
	mkdir /var/log/vuls;
	chown $ID /var/log/vuls
	chmod 700 /var/log/vuls
	mkdir -p $GOPATH/src/github.com/kotakanbe;
	cd $GOPATH/src/github.com/kotakanbe;
	git clone https://github.com/kotakanbe/go-cve-dictionary.git;
	git clone https://github.com/kotakanbe/goval-dictionary.git;
	cd $GOPATH/src/github.com/kotakanbe/go-cve-dictionary; 
	make install;
	cd $GOPATH/src/github.com/kotakanbe/goval-dictionary;
	make install;



	echo -e "$RED""Vuls installing...""$NC";
	mkdir -p $GOPATH/src/github.com/future-architect;
	cd $GOPATH/src/github.com/future-architect;
	git clone -b add-report-csv-formatlist_v3 https://github.com/gy741/vuls.git;
	cd vuls;
	make install; 

	cp $GOPATH/bin/go-cve-dictionary /usr/local/bin/
	cp $GOPATH/bin/goval-dictionary /usr/local/bin/
	cp $GOPATH/bin/vuls /usr/local/bin/
	echo "Done."; 
}

# https://github.com/namhyung/uftrace/blob/master/misc/install-deps.sh
if [ "x$(id -u)" != x0 ]; then
	echo "You might have to run it as root user."
	echo "Please run it again with 'sudo'."
	echo
	exit
fi

OPT="${@}"

distro=$(grep "^ID=" /etc/os-release | cut -d\= -f2 | sed -e 's/"//g')
if [ $distro = "" ]; then
	# Use the other way to detect the OS for CentOS 6.x
	distro=$(cat /etc/redhat-release | awk '{print tolower($1)}')
fi

case $distro in
	"ubuntu" | "pop")
		apt-get update
		apt-get $OPT install sqlite git gcc make wget
		filename="$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1)";
		install_go $filename
		install_vuls;;
	"raspbian")
		apt-get update
		apt-get $OPT install sqlite git gcc make wget
		filename="$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-armv6l.tar\.gz' | head -n 1)";
		install_go $filename
		install_vuls;;
	"rhel" | "centos")
		yum $OPT install sqlite git gcc make wget
		filename="$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1)";
		install_go $filename
		install_vuls;;
	*) # we can add more install command for each distros.
		echo "\"$distro\" is not supported distro, so please install packages manually." ;;
esac
