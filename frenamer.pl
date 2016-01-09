#!/usr/bin/perl -w
=comment
 Author: Jason Campisi  	
 Contact: aitsinformation at gmail.com
 Date: 9.29.2007 -> 2016
 License: GPL v2 or higher <http://www.gnu.org/licenses/gpl.html>
 Tested on perl v5.X built for Linux and Mac OS X Leopard or higher
=cut

#new feature: target only folders        <-- -tdn
#new feature: target by filesize      	 <--DONE  example -tf=200.32kb
#new feature: target by filessize type   <--DONE  example -tfu=mb
use strict;
use Getopt::Long;
use File::Find;
use Fcntl  ':flock';                 #import LOCK_* constants;
use constant SLASH=>qw(/);           #default: forward SLASH for *nix based filesystem path
use constant DATE=>qw(2007->2016);
my ($v,$progn)=qw(1.7.0 frenamer);
my ($fcount, $rs, $verbose, $confirm, $matchString, $replaceMatchWith, $startDir, $transU, $transD, 
    $version, $help, $fs, $rx, $force, $noForce, $noSanitize, $silent, $extension, $transWL, $dryRun, 
    $sequentialAppend, $sequentialPrepend, $renameFile, $startCount, $idir, $timeStamp, $targetDirName,
    $targetFilesize,$targetSizetype)
	=(0, 0, 0, 0, "", "", qw(.), 0, 0, "", "", 0, 0, 0, 0, 0, 0, "", 0, 0, 0, 0, "", 0, 0, 0, 0, "","");


GetOptions(
	   "f=s"  =>\$matchString,       "tu" =>\$transU,         "d=s"     =>\$startDir,
	   "s:s"  =>\$replaceMatchWith,  "td" =>\$transD,         "v"       =>\$verbose,
	   "c"    =>\$confirm,	    	 "r"  =>\$rs,             "version" =>\$version,
	   "fs"   =>\$fs,                "x"  =>\$rx,             "help"    =>\$help,
	   "y"    =>\$force,             "n"  =>\$noForce,        "silent"  =>\$silent,
	   "e=s"  =>\$extension,         "ns" =>\$noSanitize,     "sa"      =>\$sequentialAppend,
	   "dr"   =>\$dryRun,            "tw" =>\$transWL,        "sp"      =>\$sequentialPrepend,
	   "rf=s" =>\$renameFile,        "id" =>\$idir,           "sn:s"    =>\$startCount,
	   "ts"   =>\$timeStamp,         "tdn" =>\$targetDirName, "tfu:s"   =>\$targetSizetype,
	   "tf:s" =>\$targetFilesize);
	    
$SIG{INT} = \&sig_handler;


sub sig_handler{ 	#capture Ctrl+C signals
  my $signal=shift;
  die "\n $progn v$v: Signal($signal) ~~ Forced Exit!\n";
}#end sig_handler

sub cmdlnParm(){	#display the program usage info 
 if($version){ print "v$v ... by Jason Campisi ... Copyleft ". DATE . " Released under the the GPL v2 or higher\n";}
 else{  my $n=qw($1);	#use $n to overt throwing a concatenation error
 print <<EOD;
   
   Usage: $progn optionalOptions -f=match -s=replaceWith -d=/folder/path
   
   Description: $progn -- A powerful bulk file renaming program

	-f=foo            Default ""   Find--match this string 
	-s=bar            Default ""   Substitute--replace the matched string with this.
	-d=/folder/path   Default "./" Directory to begin searching within.
									
   optional:
	-dr		Dry run test to see what will happen without committing changes to files.
	-c		Confirm each file change before doing so.
	-r		Recursively search the directory tree.
	-fs		Follow symbolic links when recursive mode is on.
	-v		Verbose: show settings and all files that will be changed.
	-y		Force any changes without prompting: including overwriting a file.
	-n		Do not overwrite any files, and do not ask.
	-x		Toggle on user defined regular expression mode. Set -f for substitution: -f='s/bar/foo/'
	-ns		Do not sanitize find and replace data. Note: this is turned off when -x mode is active.
	-id		Filter: ignore changing directory names.
	-tdn 	Filter: target directory names, only.
	-sa		Sequential append a number: Starting at 1 append the count number to a filename.
	-sp		Sequential prepend a number: Starting at 1 prepend the count number to a filename.
	-ts		Add the last modified timestamp to the filename. 
			This is in the name sortable format "Year-Month-Day Hour:Minute:Second"
			Timestamp is prepended by default, but you can -sa instead.
	-rf=xxx		Completely replace filenames with this phrase & add a incrementing number to it.
	        	Only targets files within a folder, defaults to -sa but can -sp, option -r is disabled,
	        	Will replace all files, unless -f, -e, -tf, or -tst is set. 
	-e=xxx		Filter target only files with file extension XXX
	-tf=xxx		Filter target files by filesize that are at least X big. Example 1b, 10.24kb, 42.02MB, etc.
	-tfu=xxx	Filter target by filesize unit only. Choose one [B, KB, MB, GB, TB, PB, EB, ZB, YB].
	-sn=xxx 	Set the start-number count for -sa, -sp, or -rf mode to any integer > 0.
	-[tu|td|tw]	Case translation: translate up, down, or uppercase the first letter for each word.
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
    	have the number count start at 8 for files 1MB or larger.
    		$progn -tf="1mb" -sa -sn=8 -e=odt
    		file: foo.odt              result: foo 08.odt
    		...
    		file: foo bar.odt          result: foo bar 30.odt

    	Rename all jpg files to "Vacation" with a sequential number prepended to each file. Then
    	Include the files last modified timestamp appended to the name.
    		$progn -rf="Vacation" -sp -e=jpg && $progn -ts -sa -f="Vacation" -e=jpg
    		file: 2345234.jpg          result: 01 Vacation 2013-06-14 20:18:53.jpg
    		...
    		file: 2345269.jpg          result: 35 Vacation 2013-06-14 12:42:00.jpg
   
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
  until(($answer=<STDIN>)=~m/^(n|y|no|yes)/i){ print"$msg"; }

 return $answer=~m/[y|yes]/i;# ? 1 : 0 	 bool value of T/F
}#end ask($)

sub confirmChange($$@){ 	#ask if pending change is good or bad. Parameters $currentFilename and $newFilename
  return 1 if ($dryRun); 	#if dry run flag is on, then display changes, but do not comit them to file
  my ($currentf, $newf, @sizeType)=@_;  
  my $msg=" Confirm change: " . getPerms($currentf) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t \"$currentf\" to \"$newf\" [(y)es or (n)o] ";

  return ask($msg);
}#end confirmChage($)

sub getPerms($){ 	#get file permisions in *nix format. Parameter=$file to lookup
my ($file)=@_; 
 return "???" unless (-e $file && (-f $file || -d $file || -c $file) ); #does it exist? is a directory or file?
 my @perm=split "",sprintf "%04o", (lstat($file))[2] & 07777;
 my @per=("---","--x","-w-","-wx","r--","r-x","rw-","rwx");  #for decyphering file permission settings

  if(-l $file){$file="l";}      #symbolic link?
  elsif(-d $file){$file="d";}   #directory?
  elsif(-c $file){$file="c";}   #special character file?
  else{$file="-";}              #normal file
 return $file . $per[$perm[1]] . $per[$perm[2]] . $per[$perm[3]] ;	#return owner,group,global permission info 
} #end getPerms($)

sub _makeUC($){ #make it upper-case
 return uc ($_[0]); 
} #end _makeUC($) 

sub _makeLC($) { #make it lower-case
 return lc ($_[0]);
}#end _makeLC($)

sub _transToken($){ # _transToken($) send a single character to be uppercased
 ($_) = @_; 
 my $TT=\&_makeUC; #method call trick for use within regex
  $_ = _makeLC($_); #setup the filename to be all lowercase

 # Look for the word boundaries and uppercase the first aplha char
 # note: does not find _ word boundries.. ALSO, need e option for having the method call to work
   $_ =~s/\b([a-z])/$TT->($1)/ge;
 return $_;
} #end _transToken($)

sub _translateWL($){    #translate 1st letter of each word to uppercase
 ($_) = @_;
  $_ = _transToken(($_[0]));
 my $MAKELOWER=\&_makeLC;

#/* treat underscores as word boundries, also make file extensions lowercase */
 if ($_=~m/\_/){
   my @n; my $string="";
   if (@n=split /\_/, $_){ #split name into sections denoted by the '_' sybmol used in the name
        for ( my $c=0; $c <=$#n;  $c++){
             $n[$c] = _transToken($n[$c]);
             if($c==0){                                         #first case
                if ($_=~m/^\_/){ $string = "_" . $n[$c];        #check to see if it starts with a underscore
                }else {$string = $n[$c]; }                      #non-dot file format
             }elsif($c==$#n){ $_ = $string . "_" . ($n[$c]); 	#last case
             }else { $string = $string . "_" . $n[$c]; }        #all other cases
        }
   }
 }

#/* deal with dot files and file extensions  */
 if ($_=~m/^\./ && (($_=~s/(\.)/$1/g) <=1)) { #CHECK to see if there are, at most, 1 dot in the dot file name by counting how many exist
   return $_;
 } elsif ($_=~m/\./){ #make file extensions lowercase
   my @n; my $string="";
   if (@n=split /\./, $_){ #split name into sections denoted by the '.' sybmol used in the name
	for (my $c=0; $c <=$#n;  $c++){
         if($c==0){                                         	#first case
            $string = $n[$c];
	     }elsif($c==$#n){ $_ = $string . "." . _makeLC($n[$c]); #last case
	     }else { $string = $string . "." . $n[$c]; }        	#all other cases
	}
   }
   
   #Deal with files ending in two dots lowercase-- end result example: Foo.tar.gz, or Foo.txt.bak, .Foo.conf.bak
   #note: need e option for having the method call to work, & can only handle 1 method-call
   $_=~s/\.([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/$MAKELOWER->(".$1.$2")/e; 
 }#end elsif
 
 return $_;
} #end _translateWL($)

sub _translate($){	#translate case either up or down. Parameter = $file
  my ($name)=@_;
  	
    if ($name eq ""){ 
          return "";
    }elsif ($transWL){
          return _translateWL($name);
    }elsif($transD){
          return _makeLC($name);          
    }elsif($transU){
          return _makeUC($name);
    }
    return $name;
}#end _translate($)

sub timeStamp($){ #Returns timestamp of filename. Parameter = $filename
#display date info sortable format: "Year-Month-Day Hour:Minute:Second"

my ($file)=@_; 
 return $file if $file eq "" or not (-e $file); #if the file does not exist in currently folder return.
  
  my $ctime = (stat($file))[9] || return "timeStampError";
  my($sec,$min,$hour) = localtime($ctime);

 use POSIX ();
  my $fdate=POSIX::strftime("%Y-%m-%d", localtime($ctime)) . " $hour:$min:$sec" || "timeStampError";
  print " datestamp: $file -> $fdate\n" if ($verbose);
  
  return $fdate;  
}#end timeStamp

sub _sequential($){ #Append or prepend the file-count value to a name or last mod dateStamp. Parameter = $filename
#This subroutine returns a filename or an empty string for failing to update the passed $filename
# Prepend example 1: foo.txt  -> 01 foo.txt
# Prepend example 2: foo.txt  -> 11-09-2014 11:42:16 foo.txt
#  Append example 1: foo.txt  -> foo 01.txt
#  Append example 2: foo.txt  -> foo 11-09-2014 11:42:16.txt

 my ($fname)=@_;
  return $fname if ( $extension and $fname !~m/(\.$extension)$/);
  
  my $value = "";
  if ($timeStamp){
      $value = timeStamp($fname);
  }else {
      return "" if -d $fname; #when appending a number to a file, skip folders
      $value = sprintf("%002d", $fcount + 1); #insert 0 before 1->9, therefore 1 is 01
  }

  $fname = $renameFile if ($renameFile ne "");

  if( $sequentialPrepend ){ #add next file count number to the start of a filename
 	  $fname = "$value $fname";
  }elsif( $sequentialAppend ){ #add the next file count number to the end of a filename (before the extension)
 	  if ( $extension and $fname=~m/(\.$extension)$/){	# we know what it is, so insert the number before it 		
	 	   eval $fname=~s/(\.$extension)$/ $value$1/;
 	  }
 	  elsif( $fname=~m/(\..+)$/ )  { #if a file, find the unknown extension and insert the number before it
            if( $fname=~m/(\.tar\.gz)$/ ){ eval $fname=~s/(\.tar\.gz)$/ $value$1/; } 
            else { eval $fname=~s/(\..+)$/ $value$1/; }
 	  }
 	  elsif( $renameFile ne "" ){ #-rf mode & failed above test so there's no filetype in the name, stick value at the end
 	       $fname = "$fname $value";
 	  }else{ return ""; } #Can't append value to $fname  
 	  
 	  if ( $@ ){ #report any problems
		  warn " >Regex problem: appending value sequence against $fname:$@\n" if (!$silent); 
		  return "";
 	  }
  }
  
 return $fname;
} #end _sequential($)

sub formatSize($){ #find the filesize format type of a file: b, kb, mb, etc. Parameter = $fileSize in bytes 
# return's a list of (size, formatType), "size formatType"
# source, but modified to meet needs: https://kba49.wordpress.com/2013/02/17/format-file-sizes-human-readable-in-perl/
 my ($size, $exp, $units) = (shift, 0, [qw(B KB MB GB TB PB EB ZB YB)]);

  for (@$units) {
      last if $size < 1024;
      $size /= 1024;
      $exp++;
  }

  return wantarray ? (sprintf("%.2f", $size), $units->[$exp]) : sprintf("%.2f %s", $size, $units->[$exp]);
} #end formatSize($)

sub fRename($){ #file renaming... only call this when not crawling any subfolders. Parameter = $folder to look at
 my ($dir)=@_; 
 my @files;
   return -1 if (! -d $dir); #skip path if not a valid directory name
   chdir ($dir);
   if (opendir DLIST,"."){     
      eval { @files = readdir(DLIST) };
      closedir DLIST;
   }else { die "Cannot opendir: $!\n"; }
   if ( $@ ){ #report any problems
		  warn " >Problem reading $dir:\n >$@\n" if (!$silent); 
		  return -1;
   }
   #if ($verbose && !$silent){ print " Working file List:\n  \'" . join (",\' ", @files) . "\n\n"; }  #for debugging

   foreach my $fname (@files){ _rFRename($fname); }
  return 1; 
} #end frename($) 

sub _lock ($) {  #expects a filehandle reference to lock a file
  my ($FH)=@_;
   until (flock($FH, LOCK_EX)){ sleep .10; }
}#end _lock($)

sub _unlock($) { #expects a filehandle reference to unlock a file
 my ($FH)=@_;
   until (flock($FH, LOCK_UN)){ sleep .10; }
}#end _unlock($)

sub _rFRename($){ 	#recursive file renaming processing. Parameter = $filename
  my ($fname)=@_;

   print "  " . Cwd::getcwd() . SLASH . "$fname\n" if($verbose && !$silent);
   #if true discard the filename, else keep it
   return if( $fname=~m/^(\.|\.\.)$/ or                               #if a dot file 
             ($extension and $fname !~m/(\.$extension)$/) or          #discard all non-matching filename extensions
             ($idir && -d $fname) or (-d $fname && $renameFile)       #if ignore changing folder-names    
            );                                                        #if yes to any, then move along
   if (!(-w $fname)) {                                                #if not writable, then move along
       warn " --> " . Cwd::getcwd() . SLASH . "$fname is not writable, skipping file\n" if (!$silent);
       return;
   }
   my $size=(stat($fname))[7];
   return if ($targetFilesize and  $size < $targetFilesize );         #if filesize too small
   my @sizeType=formatSize($size); undef $size;
   return if ($targetSizetype and ($sizeType[1] ne $targetSizetype)); #filter out files that don't match size format type
   #end discard filenames filter
   
   my $trans=$transU+$transD+$transWL; #add the bools together.. to speed up comparisons

   if($rx || $rs || $fname=~m/$matchString/ || $trans || ($timeStamp or $sequentialAppend or $sequentialPrepend)){ #change name if
	 my $fold=$fname;  
   	 	 
	 if($renameFile){  #replace each file name with the same name with a unique number added to it
	 	#ex: foo_file.txt  -->  foobar 01.txt, foobar 02.txt, ... foobar n.txt
	 	return if( $matchString ne "" && not $fname=~m/$matchString/); 
	 	my $r = _sequential($fname);
 	 	return if ($r eq "");  #next file if if blank current filename is either a folder or failed to append or prepend number	 
 	 	$fname = $r;
 	 }
 	 elsif($rx){
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
			$fname = _translate($fname) if($transD or $transWL or $transU);
			
			if($sequentialAppend or $sequentialPrepend or $timeStamp) {
	 		   my $r = _sequential($fname);
 	 		   return if ($r eq "");  #next file if blank since current filename is either a folder or failed to append or prepend number	 
 	 		   $fname = $r;
			}
		}
	 }

	 return  if $fold eq $fname; #nothing has changed-- ignore quietly

	 if(!$force  && ($confirm || -e $fname)) {### does a file exist with that same "new" filename? should it be overwritten?
		### mod to also show file size and age of current existing file
		return if $noForce;	#dont want to force changes?
		if(-e $fname ){	 
			 print">Transformation: the following file already exists-- overwrite the file? $fname\n  --->"; 
		}

		if(!confirmChange($fold,$fname,@sizeType)){ print " -->Skipped: $fold\n" if ($verbose && !$silent);  return; }
	 }
	 
	 if($dryRun){ #dry run mode: display what the change will look like, update count then return
	    ++$fcount;
	    print " Change " . getPerms($fold) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t" . "\"$fold\" to \"$fname\"\n" if (!$silent); 
	    return;
	 }
	 
	 #lock, rename, and release the file
	 if (open (my $FH,, $fold)){
	    _lock($FH); 
	       eval { rename ($fold, $fname); };  #try to rename the old file to the new name
	    _unlock($FH);
	    close $FH;
	 }
	 	 
	 if ($@) { #where there any errors?
	     warn "ERROR-- Can't rename " . Cwd::getcwd() . SLASH . "\n\t\"$fold\" to \"$fname\": $!\n" if  (!$silent);
	 }elsif($verbose){
	     print " Updated " . getPerms($fname) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t" . "\"$fold\" to \"$fname\"\n"; 
	     ++$fcount;
	 }else{++$fcount;}
	 
   }#end filename rename clause
   
} #end _rFRename($;$)

sub intoBytes($){ #Parameters: $"filesize+unitType" example 8.39GB, returns size in bytes or -1 if fails
 my ($size) =@_;
#  byte      B
#  kilobyte  K = 2**10 B = 1024 B
#  megabyte  M = 2**20 B = 1024 * 1024 B
#  gigabyte  G = 2**30 B = 1024 * 1024 * 1024 B
#  terabyte  T = 2**40 B = 1024 * 1024 * 1024 * 1024 B
#  petabyte  P = 2**50 B = 1024 * 1024 * 1024 * 1024 * 1024 B
#  exabyte   E = 2**60 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  zettabyte Z = 2**70 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  yottabyte Y = 2**80 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B

  if ($size =~m/([-+]?[0-9]*\.?[0-9]+)\s?(B|KB|MB|GB|TB|PB|EB|ZB|YB)/ ){ #floating point number & unit-type
      my ($number, $type, $exp, $units) = (abs($1), $2, 0, [qw(B KB MB GB TB PB EB ZB YB)]);
      return $number if $type eq "B";
      for (@$units){
          if ($type eq $units->[$exp]) {
              foreach (1 .. $exp){ $number = $number * 1024;} #due to rounding errors, loop used instead of exponent 
              return $number;
          }
          $exp++;
      }
  }
  return "-1";
}#end intoBytes($)

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
  }#end foreach
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
	 print "-->Directory location: $startDir\n";
	 print "-->Use this data  { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }\n" if !$rx;
	 untaintData();
	 print "-->Data sanitized { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }\n" if !$noSanitize;
	 print "-->Start location: $startDir\n";
	 print "-->Follow symbolic links\n" if($fs);
	 print "-->Ignore changing directory names\n" if($idir);
	 print "-->Targeting only directory names\n" if($targetDirName);
	 print "-->Targeting only filesize type $targetSizetype\n" if($targetSizetype);
	 print "-->Targeting only files of at least size $targetFilesize -> " . intoBytes(uc $targetFilesize) ." bytes\n" if($targetFilesize);
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
 	 print "-->Timestamp in name\n" if ($timeStamp);
	 print "-->Name all files as $renameFile\n" if($renameFile);
 	 print "-->Start count=$startCount\n" if ($startCount);
	 print "-->Recursively traverse folder tree\n" if ($rs);
	 print "-->Dry run test\n" if($dryRun);
	 print "-->Verbose option\n" if($verbose);
	 print "-------------------------------------------------------\n Locations:\n";
   }else { untaintData(); }
}#end showUsedOptions()

sub prepData(){  # prep Data settings before the program does the real work.
   $force++ 		if $silent; #if silent-mode is on, then activate force-mode
   $noSanitize++ 	if $rx;	#don't treat regular expressions

   if (! -d $startDir ){
       if(!$silent and $force or ask("|Error: \'$startDir\' is not a valid folder!\n| Do you want to use your current location instead? ") ){
           $startDir=Cwd::getcwd();
           print "|Start location changed to: $startDir\n" if ($verbose);
       }else{ exit; }           
   }

   showUsedOptions();
   
   if ($renameFile ne ""){ #if -rf mode ensure Append/Prepend is set too
       if (($sequentialAppend eq 0 && $sequentialPrepend eq 0) or
       	   ($sequentialAppend && $sequentialPrepend) ){ #if both flags not set or both selected set to append
           $sequentialAppend = 0;  # add the end of name
           $sequentialPrepend = 1; # add to the beginning
       }
       $rs = 0; #disable, since it does not reset the number-count when going into each new folder
   }elsif (!$timeStamp && $sequentialAppend or $sequentialPrepend) { #if -sa or -sp disable -r mode
       $rs = 0; #disable, since it does not reset the number-count when going into each new folder 
   }elsif ($timeStamp && $sequentialAppend){
   		$sequentialPrepend = 0;
   }elsif ($timeStamp){
   	   $sequentialPrepend = 1;
   }
   
   if (($force and $renameFile) or ($renameFile and $extension and !($renameFile =~m/$extension$/)) and 
       ask(" The replacement filename \"$renameFile\" is missing an extension: Should it to be of filetype \"$extension\"? ") 
      ){  #should the new name use the filetype that is being targeted?
       $renameFile = sprintf("%s.%s", $renameFile, $extension); 
   }

   if (($startCount=~/^[+]?\d+$/ and $startCount > 1) and ($sequentialAppend or $sequentialPrepend)){
       #if start-count is needed ensure the start-number is a positive integer
       $fcount = $startCount - 1; #account for 0 being the first number
   }else { $startCount = 0; }

   if ($targetSizetype){
       $targetSizetype = uc $targetSizetype;
       $targetSizetype = "" if ($targetSizetype !~m/(B|KB|MB|GB|TB|PB|EB|ZB|YB)/);
   }
   if ($targetFilesize){
       $targetFilesize = uc $targetFilesize;
       if ($targetFilesize !~m/(B|KB|MB|GB|TB|PB|EB|ZB|YB)/) { $targetFilesize = "";}
       else { $targetFilesize = intoBytes($targetFilesize); } #only use this info comparing bytes so convert
   } 
   
}#end prepData()

sub main(){
  #Setup settings and messages
   cmdlnParm() 	    if ($version || $help || ($matchString eq "" && 
                       (!$transU && !$transD && !$transWL && !$renameFile &&
                        !$timeStamp && !$sequentialAppend && !$sequentialPrepend))
                    );

   prepData();
  
 #Everything is setup, now start looking for files to work with
   if ($rs){ #recursively traverse the filesystem?
       if ($fs) { File::Find::find( {wanted=> sub {_rFRename($_);}, follow=>1} , $startDir ); } #follow symbolic links?
       else{ finddepth(sub {_rFRename($_); }, $startDir); } #follow folders within folders
   }else{ fRename($startDir); }  #only look at the given base folder
   
   if(!$silent && $dryRun or $verbose) {
       print "-------------------------------------------------------\n"; 
       #does the file-count need converting?
       if (($sequentialAppend or $sequentialPrepend) && $startCount > 0) { 
           $fcount = ($fcount - $startCount) + 1;
       }
       
       if($dryRun) { print "Total Purposed Files To Changes: $fcount\n"; }
       else{ print "Total Files Changed: $fcount\n"; }
   }

}#end main()

main();		#run the code
	

__END__
