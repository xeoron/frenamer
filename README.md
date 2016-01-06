frenamer (file renamer)
========
It is time to evolve the rename program that *nix based systems use. Linux has one called, "rename", created by Larry Wall 
and it's lacking features to better manage bulk renaming of files and folders; and has not changed in over a decade. 
You deserve something better. We all do!

frenamer makes it easy to rename many files and folders using pattern matching by keywords or by using regex. It, also, includes 
features for case translation, along with word detection, force or confirm changes, follow symbolic links, rename all files to a 
certain key phrase with sequential number added to each file, target a group to share the same while only differing by a 
sequential number, dry run mode to see what changes will be made without making them, to search recursively through the 
file-system, ignore changing folder names, and even target files by file-extension.

This is Perl based program that works best on *nix based systems, such as Linux, OpenBSD, and Mac OS X. 
Note: It can run on Microsoft Windows, but is not fine-tuned for it

to install
=====
Automated setup

	sudo ./install_frenamer.sh

Manual setup

	chmod +x ./frenamer.pl
	sudo cp ./frenamer.pl /usr/bin/frenamer

usage
=====
    frenamer options -f=find -s=substitute -d=/folder/path
    
   Core settings
  
    -f=find          Default ""   Find--match this string 
    -s=substitute    Default ""   Substitute--replace the matched string with this.
    -d=/folder/path  Default "./" Directory to begin searching within.
    
   Options
   
    -dr		    Dry run test to see what will happen without committing changes to files.
    -r		    Recursively search the directory tree.
    -fs		    Follow symbolic links when recursive mode is on.
    -v		    Verbose-- show settings and all files that will be changed.
    -c		    Confirm each file change before doing so.
    -[tu|td|tw] Case translation-- translate up, down, or uppercase the first letter for each word.
    -y		    Force any changes without prompting-- including overwriting a file.
    -n		    Do not overwrite any files, and do not ask.
    -x		    Toggle on user defined regular expression mode. 
    			Set -f for substitution: -f='s/bar/foo/'
    -ns		    Do not sanitize find and replace data. 
    			Note: this is turned off when -x mode is active.
	-id		    Ignore changing directory names.	
	-sa		    Sequential append a number: Starting at 1 append the count number to a filename.
	-sp		    Sequential prepend a number: Starting at 1 prepend the count number to a filename.
	-ts		    Add the last modified timestamp to the filename. 
				This is in the name sortable format "Year-Month-Day Hour:Minute:Second"
				Timestamp is prepended by default, but you can -sa instead.
	-rf=xxx		Completely replace filenames with this phrase & add incrementing number to it.
				Only targets files within a folder.
				Defaults to -sa but can -sp, option -r is disabled, and
				will replace all files, unless -f or -e is set.
	-sn=xxx 	Set the start-number count, for -sa, -sp, or -rf mode, to any positive integer.
	-e=xxx		Target to only files with file extension XXX
    -silent	    Silent mode-- suppress all warnings, force all changes, and omit displaying results
    -help	    Usage options.
    -version    Version number.
    	
example i.
=====
   Rename all jpg files to "Vacation" with a sequential number prepended to each file. Then
   appended the files last modified timestamp to the name.
    	
    		frenamer -rf="Vacation" -sp -e=jpg && frenamer -ts -sa -f="Vacation" -e=jpg

   What happens: the program is run 2 times
        
        Run 1 targets all jpg files
   		File: 2345234.jpg		Result: 01 Vacation.jpg
   		File: 2345235.jpg		Result: 02 Vacation.jpg
   		...
   		File: 2345269.jpg		Result: 35 Vacation.jpg
   		
   		Run 2 targets jpg files with "Vacation" in the filename
   		File: 01 Vacation.jpg	Result: 01 Vacation 2013-06-14 19:28:53.jpg
   		File: 02 Vacation.jpg	Result: 02 Vacation 2013-06-14 19:30:00.jpg
   		...
   		File: 35 Vacation.jpg	Result: 35 Vacation 2013-06-15 8:14:53.jpg
	
example ii.
=====
   In the music folder and all its subfolders use a regular expression to find the blank spaces after 
   the track number and replace them with a dot. Target only ogg files, and confirm changes before 
   renaming the file.
   
    	frenamer -c -x -r -e=ogg -d=/var/music/ -f='s/^(\d+)\s+/$1./'
    	
   Result
   
    	Confirm change: -rw-rw---- /Volumes/music/Example/
       	"01   foo bar.ogg" to "01.foo bar.ogg" [(y)es or (n)o] 

example iii.
=====
   In the current folder, remove all blank spaces in names and replace them with a underscore.
   
    	frenamer -f=" "	-s="_"
   
   What happens
  
    	File: foo bar.doc       Result: foo_bar.doc
    	File: f o o.doc	        Result: f_o_o.doc

example iv.
=====
   In the current folder, upper-case the first letter of each word in a filename.
   
    	frenamer -tw
    	
   What happens
    	
    	File: foo_bar.doc  	    Result: Foo_Bar.doc
    	File: f_o_o.doc	   	    Result: F_O_O.doc

example v.
=====
   In the current folder append a number count to all the files with a odt filetype and
   have the count-number start at 8.
    	
    	frenamer -sa -sn=8 -e=odt

   What happens
   
    	File: foo.odt          	Result: foo 08.odt
		File: foo bar.odt		Result: foo bar 09.odt

example vi.
=====

   Uppercase all filenames in folder "Photos" and all subfolders contain the word "nasa" in them.
   
    	frenamer -r -tu -d=./Photos -f="nasa" -s="nasa"
    	
   What happens
    	
    	File: nasa_launch.jpg     	Result: NASA_LAUNCH.JPG

example vii.
=====

   Note about case translations: 
   If the substitute option (-s) is omitted when find option (-f) is being used, 
   then it will search for any file with the phrase "nasa" & remove it from filename 
   before the case is changed.
   
    	frenamer -r -tu -d=./images/ -f="nasa"
    
   What happens
    
    	File: nasa_launch.jpg     	Result: _LAUNCH.JPG
