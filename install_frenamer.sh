#!/bin/sh -e
echo "frenamer installer:"

echo " Setting file to executable..."
chmod +x ./frenamer.pl

echo " Checking for Perl at /usr/bin/perl ..."
if [ "$(whereis perl)" != '/usr/bin/perl' ]; then
	echo " Perl can not be found. If it is installed make a symlink that points /usr/bin/perl to the right location."
	exit 1;
fi

if [ "$(whoami)" != 'root' ]; then
	echo " You do not have permission to install frenamer.pl. Must be root user."
	exit 1;
fi

echo " Installing to /usr/bin/"
cp ./frenamer.pl /usr/bin/frenamer
echo " Setup complete!"