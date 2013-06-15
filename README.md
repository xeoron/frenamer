frenamer (file renamer)
========
It is time to evolve the rename program that *nix based systems use. Linux has one called, "rename", created by Larry Wall 
and it's lacking features to better manage bulk renaming of files and folders; and has not changed in over a decade. 
You deserve something better. We all do!

frenamer makes it easy to rename many files and folders using pattern matching by keywords or by using regex. It, also, includes 
features for case translation, along with word detection, force or confirm changes, follow symbolic links, rename all files to a 
certain key phrase with sequential number added to each file, target a group to share the same while only differing by a 
sequential number, dry run mode to see what changes will be made without making them, to search recursively through the 
file-system, and even target files by file-extension.

This is Perl based program that works best on *nix based systems, such as Linux, OpenBSD, and Mac OS X. 
Note: It can run on Microsoft Windows, but is not fine-tuned for it

To install
=====
	sudo cp ./frenamer.pl /usr/bin/frenamer

Usage
=====
    frenamer options -f=find -s=substitute -d=/folder/path
    
   Core settings
  
    -f=find          Default ""   Find--match this string 
    -s=substitute    Default ""   Substitute--replace the matched string with this.
    -d=/folder/path  Default "./" Directory to begin searching within.
    
   Options
   
    -r		    Recursively search the directory tree.
    -fs		    Follow symbolic links when recursive mode is on.
    -v		    Verbose-- show settings and all files that will be changed.
    -c		    Confirm each file change before doing so.
    -[tu|td|tw] Case translation-- translate up, down, or tu the first letter for each word.
    -y		    Force any changes without prompting-- including overwriting a file.
    -n		    Do not overwrite any files, and do not ask.
    -x		    Toggle on user defined regular expression mode. Set -f for substitution: -f='s/bar/foo/'
    -dr		    Dry run test to see what will happen without committing changes to files.
    -ns		    Do not sanitize find and replace data. Note: this is turned off when -x mode is active.
	-dr		    Dry run test to see what will happen without committing changes to files.
	-sa		    Append sequential number: Append the next count number to a filename.
	-sp		    Prepend sequential number: Prepend the next count number to a filename.
	-rf=xxx		Completely replace filenames with this phrase & add incrementing number to it.
				Only targets files within a folder, defaults to -sa but can -sp, option -r is disabled,
				Will replace all files, unless -f or -e is set.
	-sn=xxx 	Set the start-number count, for -sa, -sp, or -rf mode, to any positive integer.
	-e=xxx		Target to only files with file extension XXX
    -silent	    Silent mode-- suppress all warnings, force all changes, and omit displaying results
    -help	    Usage options.
    -version    Version number.
    	
Example I.
=====
   Rename all jpg files, in the current folder, to "Vacation 2013" with a sequential number 
   prepended to each new filename.
   		
   		frenamer -rf="Vacation 2013" -sp -e=jpg
   
   What happens

   		File: 2345234.jpg		Result: 01 Vacation 2013.jpg
   		File: 2345235.jpg		Result: 02 Vacation 2013.jpg
   		...
   		File: 2345269.jpg		Result: 35 Vacation 2013.jpg
	
Example II.
=====
   In the music folder and all its subfolders use a regular expression to find the blank spaces after 
   the track number and replace them with a dot. Target only ogg files, and confirm changes before 
   renaming the file.
   
    	frenamer -c -x -r -e=ogg -d=/var/music/ -f='s/^(\d\d)\s+/$1\./'
    	
   Result
   
    	Confirm change: -rw-rw---- /Volumes/music/Example/
       	"01   foo bar.ogg" to "01.foo bar.ogg" [(y)es or (n)o] 

Example III.
=====
   In the current folder, remove all blank spaces in names and replace them with a underscore.
   
    	frenamer -f=" "	-s="_"
   
   What happens
  
    	File: foo bar.doc       Result: foo_bar.doc
    	File: f o o.doc	        Result: f_o_o.doc

Example IV.
=====
   In the current folder, upper-case the first letter of each word in a filename.
   
    	frenamer -tw
    	
   What happens
    	
    	File: foo_bar.doc  	    Result: Foo_Bar.doc
    	File: f_o_o.doc	   	    Result: F_O_O.doc

Example V.
=====
   In the current folder append a number count to all the files with a odt filetype and
   have the count-number start at 8.
    	
    	frenamer -sa -sn=8 -e=odt

   What happens
   
    	File: foo.odt          	Result: foo 08.odt
		File: foo bar.odt		Result: foo bar 09.odt

Example VI.
=====
   Uppercase all filenames in folder X and all subfolders contain the word "nasa" in them.
   
    	frenamer -r -tu -d=./images/ -f="nasa" -s="nasa"
    	
   What happens
    	
    	File: nasa_launch.jpg     	Result: NASA_LAUNCH.JPG

Example VII.
===== 		
   Note about case translations: 
   If the substitute option (-s) is omitted when find option (-f) is being used, 
   then "NASA" will be removed from the matched filename before the case is changed.
   
    	frenamer -r -tu -d=./images/ -f="nasa"
    
   What happens
    
    	File: nasa_launch.jpg     	Result: _LAUNCH.JPG
