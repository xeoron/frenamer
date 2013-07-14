#!/bin/sh -e
#Author: Jason Campisi
#Date: 6/30/2013
#version 0.2.0
#Released under the GPL v2 or higher
NAME="frenamer"
EXT="pl"
echo "$NAME installer:";

 echo " Checking if '$NAME.$EXT' exists in the current folder..."
   if [ ! -n "$NAME.$EXT" ]; then
      echo " $NAME Error - File or folder name is not set!"
      exit 1;
   elif [ ! -e "$NAME.$EXT" ]; then
      echo " $NAME Error - The location of '$FILE' does not exist!"
      exit 1;
   fi
 echo " ...found!";

echo " Setting file to executable...";
chmod +x ./$NAME.$EXT

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
	echo " You do not have permission to install ./$NAME.$EXT";
	echo " ->You must be a root user.";
	echo " ->Try instead: sudo $0";
	exit 1;
else
	echo " Root access granted for $0";	
fi

echo " Installing $NAME to /usr/bin/ ...";
cp ./$NAME.$EXT /usr/bin/$NAME
echo " Setup complete."
echo "Testing install with this command\n>$NAME --version";
$NAME --version