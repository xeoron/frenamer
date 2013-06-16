#!/bin/sh -e
echo "frenamer installer:";

echo " Setting file to executable...";
chmod +x ./frenamer.pl

echo " Checking for Perl at /usr/bin/perl ...";
if [ "$(whereis perl)" != '/usr/bin/perl' ]; then
	echo " Error: Perl can not be found.";
	echo " ->If it is installed, then make a symlink that points /usr/bin/perl to the right location, else please install it.";
	exit 1;
else 
	echo " Perl found!";
fi

echo " Checking if you have the clearance to install this ...";
if [ "$(whoami)" != 'root' ]; then
	echo " You do not have permission to install 'frenamer.pl'";
	echo " ->You must be a root user.";
	echo " ->Try instead: sudo $0";
	exit 1;
else
	echo " Root access granted for $0";	
fi

echo " Installing to /usr/bin/ ...";
cp ./frenamer.pl /usr/bin/frenamer
echo " Setup complete!";