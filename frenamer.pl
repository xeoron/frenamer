#!/usr/bin/perl -w
=comment
 Author: Jason Campisi  	
 Contact: aitsinformation at gmail.com
 Date: 9.29.2007 -> 20013
 License: GPL v2 or higher <http://www.gnu.org/licenses/gpl.html>
 Tested on perl v5.X built for Linux and Mac OS X Leopard or higher
=cut

use strict;
use Getopt::Long;
use File::Find;
use constant SLASH=>qw(/);           #default: forward SLASH for *nix based filesystem path
use constant DATE=>qw(2007->2013);
my ($v,$progn)=qw(1.4.6 frenamer);
my ($fcount, $rs, $verbose, $confirm, $matchString, $replaceMatchWith, $startDir, $transU, $transD, 
    $version, $help, $fs, $rx, $force, $noForce, $noSanitize, $silent, $extension, $transWL, $dryRun, 
    $sequentialAppend, $sequentialPrepend, $renameFile, $startCount)
	=(0, 0, 0, 0, "", "",qw(.),0,0,"","",0, 0, 0, 0, 0, 0,"", 0, 0, 0, 0, "", 0);


GetOptions("f=s"  =>\$matchString,       "tu" =>\$transU,         "d=s"     =>\$startDir,
	   "s:s"  =>\$replaceMatchWith,  "td" =>\$transD,         "v"       =>\$verbose,
	   "c"    =>\$confirm,	    	 "r"  =>\$rs,             "version" =>\$version,
	   "fs"   =>\$fs,                "x"  =>\$rx,             "help"    =>\$help,
	   "y"    =>\$force,             "n"  =>\$noForce,        "silent"  =>\$silent,
	   "e=s"  =>\$extension,         "ns" =>\$noSanitize,     "sa"      =>\$sequentialAppend,
	   "dr"   =>\$dryRun,            "tw" =>\$transWL,        "sp"      =>\$sequentialPrepend,
	   "rf=s" =>\$renameFile,        "sn:s" =>\$startCount);
	    
$SIG{INT} = \&sig_handler;


sub sig_handler{ 	#capture Ctrl+C signals
  my $signal=shift;
  die "\n $progn v$v: Signal($signal) ~~ Forced Exit!\n";
}#end sig_handler

sub cmdlnParm(){	#display the program usage info 
 if($version){ print "v$v ... by Jason Campisi ... Copyleft ". DATE . " Released under the the GPL v2 or higher\n";}
 else{  my $n=qw($1);	#use $n to overt throwing a contactation error
 print <<EOD;
   
   Usage: $progn optionalOptions -f=match -s=replaceWith -d=/folder/path
   
   Description: $progn -- A powerful bulk file renaming program

	-f=foo            Default ""   Find--match this string 
	-s=bar            Default ""   Substitute--replace the matched string with this.
	-d=/folder/path   Default "./" Directory to begin searching within.
									
   optional:
	-r		Recursively search the directory tree.
	-fs		Follow symbolic links when recursive mode is on.
	-v		Verbose: show settings and all files that will be changed.
	-c		Confirm each file change before doing so.
	-[tu|td|tw]	Case translation: translate up, down, or tu the first letter for each word.
	-y		Force any changes without prompting: including overwriting a file.
	-n		Do not overwrite any files, and do not ask.
	-x		Toggle on user defined regular expression mode. Set -f for substitution: -f='s/bar/foo/'
	-ns		Do not sanitize find and replace data. Note: this is turned off when -x mode is active.
	-dr		Dry run test to see what will happen without committing changes to files.
	-sa		Append sequential number: Append the next count number to a filename.
	-sp		Prepend sequential number: Prepend the next count number to a filename.
	-rf=xxx		Completely replace filenames with this phrase & add a incrementing number to it.
	        	Only targets files within a folder, defaults to -sa but can -sp, option -r is disabled,
	        	Will replace all files, unless -f or -e is set. 
	-sn=xxx 	Set the start-number count, for -sa, -sp, or -rf mode, to any integer > 0.
	-e=xxx		Target to only files with file extension XXX
	-silent		Silent mode-- suppress all warnings, force all changes, and omit displaying results
	-help		Usage options.
	-version	Version number.


   Examples:
	In the music folder and all its subfolders replace the blank spaces after a the track number 
	with a dot. Target only ogg files, and confirm changes before renaming the file.
    		$progn -c -x -r -e=ogg -d=/var/music/ -f='s/^(\\d\\d)\\s+/$n\./'
    	  Result:
    		Confirm change: -rw-rw---- /Volumes/music/Example/
         	"01   foo bar.ogg" to "01.foo bar.ogg" [(y)es or (n)o] 

    	In the current folder, remove all blank spaces in filenames and replace them with an underscore.
    		$progn -f=" "	-s="_"  
    		file: foo bar.odt         result: foo bar.odt
    
    	In the current folder, upper-case the first letter of each word in a filename.
    		$progn -tw
    		file: 01.boo bar.ogg      result: 01.Foo Bar.ogg
    		
    	In the current folder append a number count to all the files with a odt filetype and
    	have the number count start at 8.
    		$progn -sa -sn=8 -e=odt
    		file: foo.odt              result: foo 08.odt
    		...
    		file: foo bar.odt          result: foo bar 30.odt

    	Rename all jpg files to "2013 Vacation" with a sequential number prepended to each file
    		$progn -rf="Vacation 2013" -sp -e=jpg
    		file: 2345234.jpg          result: 01 Vacation 2013.jpg
    		...
    		file: 2345269.jpg          result: 35 Vacation 2013.jpg
   
    	Uppercase all filenames in folder X and all subfolders contain the word "nasa" in them. 
    		$progn -r -tu -d=./images/ -f="nasa" -s="nasa"
    		file: nasa_launch.jpg     	result: NASA_LAUNCH.JPG
    		
    	Note about case translations: 
    	If the substitute option (-s) is omitted when the find option (-f) is being used, 
    	then "NASA" will be removed from the matched filename before the case is changed.
      		$progn -r -tu -d=./images/ -f="nasa"
       		file: nasa_launch.jpg     	result: _LAUNCH.JPG
EOD
}#end else
   exit;
}#end cmdlnParm()

sub ask($){
 return 1 if ($force); # Yes do it, don't ask, if either case is true
 my($msg) = @_; my $answer = "";
  
  print $msg;
  until(($answer= <STDIN>)=~m/^(n|y|no|yes)/i){ print"$msg"; }

 return $answer=~m/[y|yes]/i;# ? 1 : 0 	 bool value of T/F
}#end ask($)

sub confirmChange($$){ 	#ask if pending change is good or bad. Parameters $currentFilename and $newFilename
  return 1 if ($dryRun); 	#if dry run flag is on, then display changes, but do not comit them to file
  my ($currentf, $newf)=@_;  
  my $msg=" Confirm change: " . getPerms($currentf) . " " . Cwd::getcwd() . SLASH . "\n\t \"$currentf\" to \"$newf\" [(y)es or (n)o] ";

  return ask($msg);
}#end confirmChage($)

sub getPerms($){ 	#get file permisions in *nix format. Parameter=$file to lookup
my ($file)=@_; 
 return "???" unless (-e $file && (-f $file || -d $file || -c $file) ); #does it exist? is a directory or file?
 my @perm=split "",sprintf "%04o", (lstat($file))[2] & 07777;
 my @per=("---","--x","-w-","-wx","r--","r-x","rw-","rwx");  #for decyphering file permission settings

  if(-l $file){$file="l";} 	#symbolic link?
  elsif(-d $file){$file="d";}	#directory?
  elsif(-c $file){$file="c";}	#special character file?
  else{$file="-";}		#normal file
 return $file . $per[$perm[1]] .$per[$perm[2]] . $per[$perm[3]] ;	#return owner,group,global permission info 
} #end getPerms($)

sub _transLC($){ #take a tokenized char and make it lower case
 return uc ($_[0]); 
} #end transToken($) send a single character to be uppercased

sub _makeLC($) { #make-lower-case
 return lc ($_[0]);
}#end _makeLC($)

sub _transToken($){
 ($_) = @_; 
 my $tt=\&_transLC; #method call trick for use within regex
  $_ = _makeLC($_); #setup the filename to be all lowercase

 # Look for the word boundaries and uppercase the first aplha char
 # note: does not find _ word boundries.. ALSO, need e option for having the method call to work
   $_ =~s/\b([a-z])/$tt->($1)/ge;
 return $_;
} #end _transToken($)

sub _translateWL($){    #translate 1st letter of each word to uppercase
 ($_) = @_;
  $_ = _transToken(($_[0]));
 my $ml=\&_makeLC;

#/* treat underscores as word boundries, also make file extensions lowercase */
 if ($_=~m/\_/){
   #print "before underscore filter: $_\n";
   my @n; my $string="";
   if (@n=split /\_/, $_){ #split name into sections denoted by the '_' sybmol used in the name
        for ( my $c=0; $c <=$#n;  $c++){
             $n[$c] = _transToken($n[$c]);
             if($c==0){                                         #first case
                if ($_=~m/^\_/){ $string = "_" . $n[$c];          #check to see if it starts with a underscore
                }else {$string = $n[$c]; }                        #non-dot file format
             }elsif($c==$#n){ $_ = $string . "_" . ($n[$c]); #last case
             }else { $string = $string . "_" . $n[$c]; }        #all other cases
        }
   }
   #print "after underscore filter: $_\n";
 }

#/* deal with dot files and file extensions  */
 if ($_=~m/^\./ && (($_=~s/(\.)/$1/g) <=1)) { #CHECK to see if there are, at most, 1 dot in the dot file name by counting how many exist
   return $_;
 } elsif ($_=~m/\./){ #make file extensions lowercase
   my @n; my $string="";
   if (@n=split /\./, $_){ #split name into sections denoted by the '.' sybmol used in the name
	for (my $c=0; $c <=$#n;  $c++){
         if($c==0){                                         #first case
            $string = $n[$c];
	     }elsif($c==$#n){ $_ = $string . "." . lc ($n[$c]); #last case
	     }else { $string = $string . "." . $n[$c]; }        #all other cases
	}
   }

   if( $_=~m/\.([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/ ){ #Deal with files ending in two dots lowercase-- end result example: Foo.tar.gz, or Foo.txt.bak, .Foo.conf.bak
      #print "$1 | 1: $1, 2: $2\n";
       $_=~s/\.([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/$ml->(".$1.$2")/e; 
      #note: need e option for having the method call to work, & can only handle 1 method-call
   	  #print "$2 | 1: $1, 2: $2\n"; exit;
   }
 }
 
 #print "after: $_\n";
 return $_;
} #end _translateWL($)


sub _translate($){	#translate case either up or down. Parameter = $file
  ($_)=@_;
	return if $_ eq "";
	$_ = uc $_   if($transU);
	$_ = lc $_   if($transD);
	$_ = _translateWL($_) if ($transWL);
	#print "foo: $_\n";
  return $_;
}#end _translate($)

sub _sequential($){ #Append or prepend the file-count value to a name. Parameter = $filename
#This subroutine returns a filename or an empty string for failing to update the passed $filename
# Prepend example: foo.txt  -> 01 foo.txt
# Append  example: foo.txt  -> foo 01.txt
 my ($fname)=@_;
 return "" if -d $fname; #when appending a number to a file, skip folders

 my $c = sprintf("%002d", $fcount + 1); #insert 0 before 1->9, therefore 1 is 01

  $fname = $renameFile if ($renameFile ne "");

  if ( $sequentialPrepend ){ #add next file count number to the start of a filename
	   $fname = "$c $fname";
  }elsif( $sequentialAppend ){ #add the next file count number to the end of a filename (before the extension)
 	  if ( $extension and $fname=~m/(\.$extension)$/){	# we know what it is, so insert the number before it 		
	 	   eval $fname=~s/(\.$extension)$/ $c$1/;
 	  }
 	  elsif( $fname=~m/(\..+)$/ )  { #if a file, find the unknown extension and insert the number before it
           if( $fname=~m/(\.tar\.gz)$/ ){ eval $fname=~s/(\.tar\.gz)$/ $c$1/; }
           else { eval $fname=~s/(\..+)$/ $c$1/; }
 	  }
 	  elsif( $renameFile ne "" ){ #-rf mode & failed above test so there's no filetype in the name, stick number at the end
 	       $fname = "$fname $c";
 	  }else{ return ""; } #Can't append number to $fname  
 	  
 	  if ( $@ ){ #report any problems
		  warn " >Regex problem: appending number sequence against $fname:$@\n" if (!$silent); 
		  return "";
 	  }
  }
  
 return $fname;
} #end _sequential($)

sub fRename($){ #file renaming... only call this when not crawling any subfolders. Parameter = $folder to look at
 my ($dir)=@_; 
 my @files;
   return -1 if (! -d $dir); #skip path if not a valid directory name
   chdir ($dir);
   opendir DLIST,"." or die "Cannot opendir: $!\n";    
     eval { @files = readdir(DLIST) };
   closedir DLIST;
   if ( $@ ){ #report any problems
		  warn " >Problem reading $dir:\n >$@\n" if (!$silent); 
		  return -1;
   }
   #if ($verbose && !$silent){ print " Working file List:\n  \'" . join (",\' ", @files) . "\n\n"; }  #for debugging

   foreach my $fname (@files){ _rFRename($fname); }
   
} #end frename($) 

sub _rFRename($){ 	#recursive file renaming processing. Parameter = $file
  my ($fname)=@_;

   print "  " . Cwd::getcwd() . SLASH . "$fname\n" if($verbose && !$silent);
   return if($fname=~m/^(\.|\.\.)$/); #if not writable, then move along to another file (!-w $fname) or 
   return if($extension and !($fname=~m/\.$extension$/)); #if filter by extension is on, discard all non-matching filetypes
   return if(-d $fname && ($renameFile or $sequentialAppend or $sequentialPrepend));

    
   my $trans=$transU+$transD+$transWL; #add the bools together.. to speed up comparisons

   if($rx || $rs || $fname=~m/$matchString/ || $trans || ($sequentialAppend or $sequentialPrepend)){ #change name if
	 my $fold=$fname;  
   	 	 
	 if($renameFile){  #replace each file name with the same name with a unique number added to it
	 	#ex: foo_file.txt  -->  foobar 01.txt, foobar 02.txt, ... foobar n.txt
	 	return if( $matchString ne "" && not $fname=~m/$matchString/); 
	 	my $r = _sequential($renameFile);
 	 	return if ($r eq "");  #next file if if blank current filename is either a folder or failed to append or prepend number	 
 	 	$fname = $r;
 	 }
 	 elsif ($rx){
		#using regex for translation: example where f='s/^(foo)gle/$1bar/'  or f='y/a-z/A-Z/'  or f='s/(foo|foobar)/bar/g'	
		$_=$fname if !$rs;
		eval $matchString;
		if ($@){ warn " >Regex problem against file name $fname: $@s\n" if (!$silent); }
		else { $fname = _translate($_) if ($fname ne $_); } #if the name was changed, next try translation	
	 }
	 else{#all other cases that are not using Regex
		if (($matchString eq "" && $trans) or $fname=~m/$matchString/){
			if(not ($matchString eq "" && $trans) && 
			   not ($replaceMatchWith eq "" and ($sequentialAppend or $sequentialPrepend) )) 
			{
			   eval $fname=~s/$matchString/$replaceMatchWith/g; 
			   if ($@){ 
				   warn " >Regex problem against $fname:$@\n" if (!$silent);
				   return;
			   }
			}
			$fname = _translate($fname);
			
			if($sequentialAppend or $sequentialPrepend) {
	 		   my $r = _sequential($fname);
 	 		   return if ($r eq "");  #next file if blank since current filename is either a folder or failed to append or prepend number	 
 	 		   $fname = $r;
			}
		}
	 }

	 return  if $fold eq $fname; #nothing has changed-- ignore quietly

	 if(!$force  && ($confirm || -e $fname)) {### does a file exist with that same "new" filename? should it be overwritten?
		### mod to also show file size and age of current existing file
		if(-e $fname and !$noForce){	 
			 print">Transformation: the following file already exists-- overwrite the file? $fname\n  --->"; 
		}
		return if $noForce;	#dont want to force changes?
		if(!confirmChange($fold,$fname)){ print " -->Skipped: $fold\n" if ($verbose && !$silent);  return; }
	 }
	 
	 if($dryRun){ #dry run mode: display what the change will look like! 
	    ++$fcount;
	    print" Change \"$fold\" to \"$fname\"\n\t" . getPerms($fold) . " " . Cwd::getcwd() . SLASH . "\n" if (!$silent);
	   return;
	 }
	 
	 #lock, rename, and release the file
     opendir DLIST,"." or die "Cannot opendir: $!\n";
        eval { rename ($fold, $fname); };	#try to rename the old file to the new name
       
        if ($@) { #where there any errors?
           warn "ERROR-- Can't rename " . Cwd::getcwd() . SLASH . "\n\t\"$fold\" to \"$fname\": $!\n" if  (!$silent);
  	    }else {
  	       if ($verbose){
             print" Updated \"$fold\" to \"$fname\"\n\t" . getPerms($fname) . " " . Cwd::getcwd() . SLASH . "\n"; 
             ++$fcount;
           }
	    }
     closedir DLIST;
   }#end filename rename clause
   
} #end _rFRename($;$)

sub _untaintData ($$){	#dereference any reserved non-word characters. Parameter = string of data to untaint, flag
 			#flag: >0 run through all filters, <=0 omit some filters
   my ($flag,$s)= (pop @_, ""); ($_)=@_;

   foreach (split //, $_) {		#tokenize and massage special characters
	if (/^(\W)$/){
		if ($1 eq "("){ $_ =qw(\\\(); }
		elsif ($1 eq ")"){ $_ =qw(\\\)); }
		elsif ($1 eq "\^" && $flag){ $_ =qw(\\^); }
		elsif ($1 eq "\$" && $flag){ $_ =qw(\\$); }
		elsif ($1 eq "\+" && $flag){ $_ =qw(\\+); }
		elsif ($1 eq "\*" && $flag){ $_ =qw(\\*); }
		elsif ($1 eq "\?" && $flag){ $_ =qw(\\?); }
		elsif ($1 eq "\[" && $flag){ $_ =qw(\\[); }
		elsif ($1 eq "\]" && $flag){ $_ =qw(\\]); }
		elsif ($1 eq "\." && $flag){ $_ =qw(\\.); }
		elsif ($1 eq "|" && $flag){ $_ =qw(\\|); }
		elsif ($1 eq "\\"){ $_ ="\\" . "\\";}
		elsif ($1 eq "/"){ $_ =qw(\\/);}
		elsif ($1 eq "\!"&& $flag){ $_ =qw(\\!); }
	}
	$s.=$_;
  }
  return $s;
}#end _untaintData($)

sub untaintData(){					#sanitize provided input data
   return if $noSanitize || $rx;	#don't treat regular expressions or when asked to turn sanitize mode off
   $matchString=_untaintData($matchString,1);
   $replaceMatchWith=_untaintData($replaceMatchWith,0);
}#end untaintData()

sub showUsedOptions() {
   if($verbose && !$silent){ #show which settings that will be used
	 print "$progn v$v settings:\n";
	 print "-->Use this data  { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }\n" if !$rx;
	 untaintData();
	 print "-->Data sanitized { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }\n" if !$noSanitize;
	 print "-->Start location: $startDir\n";
	 print "-->Follow symbolic links\n" if($fs);
	 print "-->Confirm changes\n" if($confirm);
	 print "-->Force changes\n" if($force);
	 print "-->Don't overwrite files\n" if($noForce);
	 print "-->Target extension $extension\n" if($extension);
	 print "-->Regular expression mode\n" if($rx);
	 print "-->Case-Translate Upper-to-Lower\n" if($transD);
	 print "-->Case-Translate Lower-to-Upper\n" if($transU);
	 print "-->Case-Translate 1st letter per word to uppercase\n" if($transWL);
	 print "-->Sequential file count: append number to file name\n" if($sequentialAppend);
	 print "-->Sequential file count: prepend number to file name\n" if($sequentialPrepend);
	 print "-->Name all files as $renameFile\n" if($renameFile);
 	 print "-->Start count=$startCount\n" if ($startCount);
	 print "-->Recursively traverse folder tree\n" if ($rs);
	 print "-->Dry run test\n" if($dryRun);
	 print "-->Verbose option\n" if($verbose);
	 print "-------------------------------------------------------\n Locations:\n";
   }else { untaintData(); }
}#end showUsedOptions()

sub prepData(){
   $force++ 		if $silent; #if silent-mode is on, then activate force-mode
   $noSanitize++ 	if $rx;	#don't treat regular expressions

   showUsedOptions();
   
   if ($renameFile ne ""){ #if -rf mode ensure Append/Prepend is set too
       if ($sequentialAppend eq 0 && $sequentialPrepend eq 0){ #if both flags not selected set to append
           $sequentialAppend = 1;
           $sequentialPrepend = 0;
       }
       $rs = 0; #disable, since it does not reset the number-count when going into each new folder
   }elsif ($sequentialAppend or $sequentialPrepend) { #if -sa or -sp disable -r mode
       $rs = 0; #disable, since it does not reset the number-count when going into each new folder 
   }   
   
   if (($renameFile and $extension and !($renameFile =~m/$extension$/)) and
       ask(" The replacement filename \"$renameFile\" is missing an extension: Should it to be of filetype \"$extension\"? ") 
      ){  #should the new name use the filetype that is being targeted?
       $renameFile = sprintf("%s.%s", $renameFile, $extension); 
   }

   if (($startCount=~/^[+]?\d+$/ and $startCount > 1) and ($sequentialAppend or $sequentialPrepend)){
       #if start-count is needed ensure the start-number is a positive integer
       $fcount = $startCount - 1; #account for 0 being the first number
   }else { $startCount = 0; }   
}#end prepData()

sub main(){
  #Setup settings and messages
   cmdlnParm() 	    if ($version || $help || ($matchString eq "" && 
                       (!$transU && !$transD && !$transWL && !$renameFile &&
                        !$sequentialAppend && !$sequentialPrepend))
                    );
  
  prepData();
  
 #Everything is setup, now start looking for files to work with
   if ($rs){ #recursively traverse the filesystem?
       if ($fs) { File::Find::find( {wanted=> sub {_rFRename($_);}, follow=>1} , $startDir ); } #follow symbolic links?
       else{ finddepth(sub {_rFRename($_); }, $startDir); } #follow folders within folders
   }else{ fRename($startDir); }  #only look at the given base folder
   
   if($verbose && !$silent) {
       print "-------------------------------------------------------\n"; 
       #does the file-count need converting?
       if (($sequentialAppend or $sequentialPrepend) && $startCount > 0) { 
           $fcount = ($fcount - $startCount) + 1;
       }
       
       if($dryRun) { print "Total purposed files to change: $fcount\n"; }
       else{ print "Total files changed: $fcount\n"; }
   }

}#end main()

main();		#run the code
	

__END__
