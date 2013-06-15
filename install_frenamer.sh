#!/bin/sh -e
echo "frenamer installer:"

echo " Setting file to executable..."
chmod +x ./frenamer.pl

echo " Checking for Perl at /usr/bin/perl ..."
if [ "$(whereis perl)" != '/usr/bin/perl' ]; then
	echo " Perl can not be found."
	echo " ->If it is installed, then make a symlink that points /usr/bin/perl to the right location."
	exit 1;
fi

if [ "$(whoami)" != 'root' ]; then
	echo " You do not have permission to install 'frenamer.pl'."
	echo " ->You must be a root user."
	echo " ->Try instead: sudo $0"
	exit 1;
fi

echo " Installing to /usr/bin/"
cp ./frenamer.pl /usr/bin/frenamer
echo " Setup complete!"