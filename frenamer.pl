#!/usr/bin/perl -w
=comment
 Authors: Jason Campisi, and includes duplicate file finding code by Antonio Bellezza
 Date: 9.29.2007 -> 2024
 License: GPL v2 or higher <http://www.gnu.org/licenses/gpl.html> unless noted.
          findDupelicateFiles() & supporting code is GPL v2 
 Tested on perl v5.X built for Linux and macOS
=end comment
=cut

use strict;
use Getopt::Long;
use File::Find;
no warnings 'File::Find';
use Fcntl  ':flock';                 #import LOCK_* constants;
use constant SLASH=>qw(/);           #default: forward SLASH for *nix based filesystem path
my $DATE="2007->". (1900 + (localtime())[5]);
my ($v,$progn)=qw(1.12.17-2 frenamer);
my ($fcount, $rs, $verbose, $confirm, $matchString, $replaceMatchWith, $startDir, $transU, $transD, 
    $version, $help, $fs, $rx, $force, $noForce, $noSanitize, $silent, $extension, $transWL, $dryRun, 
    $sequentialAppend, $sequentialPrepend, $renameFile, $startCount, $idir, $timeStamp, $targetDirName,
    $targetFilesize,$targetSizetype, $dsStore, $noSort, $duplicateFiles)
	=(0, 0, 0, 0, "", "", qw(.), 0, 0, "", "", 0, 0, 0, 0, 0, 0, "", 0, 0, 0, 0, "", 0, 0, 0, 0, "","", 0,0, 0);


GetOptions(
	   "f=s"  =>\$matchString,       "tu" =>\$transU,         "d=s"     =>\$startDir,
	   "s:s"  =>\$replaceMatchWith,  "td" =>\$transD,         "v"       =>\$verbose,
	   "c"    =>\$confirm,           "r"  =>\$rs,             "version" =>\$version,
	   "fs"   =>\$fs,                "x"  =>\$rx,             "h|help"  =>\$help,
	   "y"    =>\$force,             "n"  =>\$noForce,        "silent"  =>\$silent,
	   "e=s"  =>\$extension,         "ns" =>\$noSanitize,     "sa"      =>\$sequentialAppend,
	   "dr"   =>\$dryRun,            "tw" =>\$transWL,        "sp"      =>\$sequentialPrepend,
	   "rf=s" =>\$renameFile,        "id" =>\$idir,           "sn:s"    =>\$startCount,
	   "ts"   =>\$timeStamp,         "tdn"=>\$targetDirName,  "tfu:s"   =>\$targetSizetype,
	   "tf:s" =>\$targetFilesize,    "ds" =>\$dsStore,        "nosort"  =>\$noSort,
	   "dup"  =>\$duplicateFiles);
	    
$SIG{INT} = \&sig_handler;

sub sig_handler{ 	#capture Ctrl+C signals
  my $signal=shift;
  die "\n $progn v$v: Signal($signal) ~~ Forced Exit!\n";
}#end sig_handler


sub cmdlnParm(){	#display the program usage info 
 if($version){ print "v$v ... by Jason Campisi ... Copyleft $DATE Released under the the GPL v2 or higher\n";}
 else{  my $n=qw($1);	#use $n to overt throwing a concatenation error
 print <<EOD;
   
   Usage: $progn optionalOptions -f=match -s=replaceWith -d=/folder/path
   
   Description: $progn -- A powerful bulk file renaming program

	-f=foo            Default ""   Find--match this string 
	-s=bar            Default ""   Substitute--replace the matched string with this.
	-d=/folder/path   Default "./" Directory to begin searching within.
									
  optional:
	-dr      Dry run mode test to see what will happen without committing changes to files.
	-nosort  Turn off case insensitive file sorting before processing in dry-run mode.
	-c       Confirm each file change before doing so.
	-r       Recursively search the directory tree.
	-fs      Follow symbolic links when recursive mode is on.
	-v       Verbose: show settings and all files that will be changed.
	-y       Force any changes without prompting: including overwriting a file.
	-n       Do not overwrite any files, and do not ask.
	-x       Toggle on user defined regular expression mode. Set -f for substitution: -f='s/bar/foo/'
	-ns      Do not sanitize find and replace data. Note: this is turned off when -x mode is active.
	-ds      Delete .DS_Store files along the target location path in macOS. Dry run mode not supported.
	-id      Filter: ignore changing directory names.
	-tdn     Filter: target directory names, only.
	-sa      Sequential append a number: Starting at 1 append the count number to a filename.
	-sp      Sequential prepend a number: Starting at 1 prepend the count number to a filename.
	-ts      Add the last modified timestamp to the filename. 
	          This is in the name sortable format "Year-Month-Day Hour:Minute:Second"
	          Timestamp is prepended by default, but you can -sa instead.
	-sn=xxx      Set the start-number count for -sa, -sp, or -rf mode to any integer > 0.
	-rf=xxx      Completely replace filenames with this phrase & add a incrementing number to it.
	              Only targets files within a folder, defaults to -sa but can -sp, option -r is disabled,
	              Will replace all files, unless -f, -e, -tf, or -tst is set. 
	-e=xxx       Filter target only files with file extension XXX
	-tf=xxx      Filter target files by filesize that are at least X big. Example 24b, 10.24kb, 42.02MB, etc.
	-tfu=xxx     Filter target by filesize unit only. Choose one: [B, KB, MB, GB, TB, PB, EB, ZB, YB, BB, GPB]
                [B]bytes,      [KB]kilobyte,   [MB]megabytes, [GB]gigabyte, 
                [TB]terabyte,  [PB]petabyte,   [EB]exabyte,   [ZB]zettabyte,
                [YB]yottabyte, [BB]brontobyte, [GPB]geopbyte
	-[tu|td|tw]  Case translation: translate up, down, or uppercase the first letter for each word.
	-dup         Find & delete duplicate files at folder location. 
	              Skip or choose which one to keep. Note: file sorting is not supported.
	              Supports: Dry run, target file by extension, & force removes all files, but the 1st.
	-silent      Silent mode-- suppress all warnings, force all changes, and omit displaying results
	-h|help      Usage options.
	-version     Version number.


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

    	Rename all jpg files to "Vacation" with a sequential number prepended to each file. 
        Next, include the files last modified timestamp appended to the name.
    		$progn -rf="Vacation" -sp -e=jpg && $progn -ts -sa -f="Vacation" -e=jpg
    		file: 2345234.jpg          result: 01 Vacation 2013-06-14 20:16:53.jpg
    		file: 2345235.jpg          result: 02 Vacation 2013-06-14 20:18:24.jpg
    		...
    		file: 2345269.jpg          result: 35 Vacation 2013-06-14 12:42:00.jpg

    	In your music folder, do a dry run search for duplicate files that are of type mp3.
    		frenamer -d=/var/music/ -dr -dup -e=mp3
    		Possible duplicates: size 27.74 MB
    		 [1] -rw-r--r-- /var/music/David_Bowie/10.The_Ice_Cave.mp3
    		 [2] -rwxr-xr-x /var/music/David_Bowie/10.The_Ice_Cave(2).mp3
   
    	Uppercase all filenames in folder X and all subfolders that contain the word "nasa" in them. 
    		$progn -r -tu -d=./images/ -f="nasa" -s="nasa"
    		file: nasa_launch.jpg     	result: NASA_LAUNCH.JPG
    		
    	Case translations: 
    	If the substitute option (-s) is omitted when the find option (-f) is being used, 
    	then the -f keyword will be removed from the matched filename before the case is changed.
      		$progn -r -tu -d=./images/ -f="nasa"
       		file: nasa_launch.jpg     	result: _LAUNCH.JPG
       		
       	Warning: All filename changes are final. ALWAYS use dry run or confirm mode on files before changing them.
        
        Copyleft $DATE
EOD
}#end else
   exit;
}#end cmdlnParm()


sub ask($) {                #ask the user a question. Parameters = $message
 return 1 if ($force); # Yes do it, don't ask, if either case is true
 my($msg) = @_; my $answer = "";
  
  print $msg;
  until(($answer=<STDIN>)=~m/^(n|y|no|yes)/i){ print"$msg"; }

 return $answer=~m/[y|yes]/i;# ? 1 : 0 	 bool value of T/F
}#end ask($)


sub confirmChange($$@) { 	#ask if pending change is good or bad. Parameters = $currentFilename, $newFilename, @typeOf_FileSize
  return 1 if ($dryRun); 	#if dry run flag is on, then display changes, but do not comit them to file
  my ($currentf, $newf, @sizeType)=@_;  
  
  return ask(" Confirm change: " . getPerms($currentf) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t \"$currentf\" to \"$newf\" [(y)es or (n)o] ");
}#end confirmChage($)


sub getPerms($) { 	#get file permisions in *nix format. Parameter = $file_to_lookup
my ($file)=@_; 
 return "???" unless (-e $file && (-f $file || -d $file || -c $file) ); #does it exist? is a directory or file?
 my @perm=split "",sprintf "%04o", (lstat($file))[2] & 07777;
 my @per=("---","--x","-w-","-wx","r--","r-x","rw-","rwx");  #for decyphering file permission settings

  if (-l $file){ $file="l"; }      #symbolic link?
  elsif (-d $file){ $file="d"; }   #directory?
  elsif (-c $file){ $file="c"; }   #special character file?
  else { $file="-"; }              #normal file
 return $file . $per[$perm[1]] . $per[$perm[2]] . $per[$perm[3]] ;	#return owner,group,global permission info 
} #end getPerms($)


sub _makeUC($) { #make first char upper-case for regex. Parameters = $character
 return uc ($_[0]); 
} #end _makeUC($) 


sub _makeLC($) { #make first char lower-case for regex. Parameters = $character
 return lc ($_[0]);
}#end _makeLC($)


sub _transToken($) { # _transToken($) send a single character to be uppercased. Parameters = $character
 ($_) = @_; 
 my $TT=\&_makeUC; #Poiner method call trick for use within regex
  $_ = lc $_; #set the filename to be all lowercase

 # Look for the word boundaries and uppercase the first aplha char
 # note: does not find _ word boundries.. ALSO, need e option for having the method call to work
   $_ =~s/\b([a-z])/$TT->($1)/ge;
 return $_;
} #end _transToken($)


sub _translateWL($) {    #translate 1st letter of each word to uppercase. Parameters = $filename
 ($_) = @_;
  $_ = _transToken(($_[0]));
 my $MAKELOWER=\&_makeLC; #Pointer method call trick for use within regex

#/* treat underscores as word boundries, also make file extensions lowercase */
 if ($_=~m/\_/){
   my @n; my $string="";
   if (@n=split /\_/, $_){ #split name into sections denoted by the '_' sybmol used in the name
        for ( my $c=0; $c <=$#n;  $c++){
             $n[$c] = _transToken($n[$c]);
             if ($c==0){                                        #first case
                if ($_=~m/^\_/){ $string = "_" . $n[$c]; }      #check to see if it starts with a underscore
                else {$string = $n[$c]; }                       #non-dot file format
             }elsif ($c==$#n){ $_ = $string . "_" . ($n[$c]);  	#last case
             }else { $string = $string . "_" . $n[$c]; }        #all other cases
        }
   }
 }

#/* deal with dot files and file extensions  */
 if ($_=~m/^\./ && (($_=~m/(\.)/g) <=1)) { #CHECK to see if there are, at most, 1 dot in the dot file name by counting how many exist
   return $_;
 } elsif ($_=~m/\./){ #make file extensions lowercase
   my @n; my $string="";
   if (@n=split /\./, $_){ #split name into sections denoted by the '.' sybmol used in the name
      for (my $c=0; $c <=$#n;  $c++){
        if ($c==0){ $string = $n[$c]; }                       	   #first case
	      elsif ($c==$#n){ $_ = $string . "." . _makeLC($n[$c]); }  #last case
	      else { $string = $string . "." . $n[$c]; }        	     #all other cases
      }
   }
   
   #Deal with files ending in two dots lowercase-- end result example: Foo.tar.gz, or Foo.txt.bak, .Foo.conf.bak
   #note: need e option for having the method call to work, & can only handle 1 method-call
   $_=~s/\.([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/$MAKELOWER->(".$1.$2")/e; 
 }#end elsif
 
 return $_;
} #end _translateWL($)


sub _translate($) {	#translate case either up or down. Parameter = $file
  my ($name)=@_;
  	
   if ($name eq ""){ return ""; }
   elsif ($transWL){ return _translateWL($name); } #translate words first letter uppercase rest of a word lower
   elsif ($transD){ return lc $name; } #lowercase
   elsif ($transU){ return uc $name; } #uppercase

  return $name;
}#end _translate($)


sub timeStamp($) { #Returns timestamp of filename. Parameter = $filename
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

sub _sequential($) { #Append or prepend the file-count value to a name or last mod dateStamp. Parameter = $filename
#This subroutine returns a filename or an empty string for failing to update the passed $filename
# Prepend example 1: foo.txt  -> 01 foo.txt
# Prepend example 2: foo.txt  -> 11-09-2014 11:42:16 foo.txt
#  Append example 1: foo.txt  -> foo 01.txt
#  Append example 2: foo.txt  -> foo 11-09-2014 11:42:16.txt

 my ($fname)=@_;
  return $fname if ( $extension and $fname !~m/(\.$extension)$/i);
  
  my $value = "";
  if ($timeStamp){
      $value = timeStamp($fname);
  } else {
      return "" if -d $fname; #when appending a number to a file, skip folders
      $value = sprintf("%002d", $fcount + 1); #insert 0 before 1->9, therefore 1 is 01
  }

  $fname = $renameFile if ($renameFile ne "");

  if ( $sequentialPrepend ){ #add next file count number to the start of a filename
       $fname = "$value $fname";
  }elsif ( $sequentialAppend ){ #add the next file count number to the end of a filename (before the extension)
     if ( $extension and $fname=~m/(\.$extension)$/i){	# we know what it is, so insert the number before it 		
          eval $fname=~s/(\.$extension)$/ $value$1/i;
     } elsif ( $fname=~m/(\..+)$/ )  { #if a file, find the unknown extension and insert the number before it
          if ( $fname=~m/(\.tar\.gz)$/ ){ eval $fname=~s/(\.tar\.gz)$/ $value$1/; } 
          else { eval $fname=~s/(\..+)$/ $value$1/; }
     } elsif ( $renameFile ne "" ){ #-rf mode & failed above test so there's no filetype in the name, stick value at the end
          $fname = "$fname $value";
     } else { return ""; } #Can't append value to $fname  
 	  
     if ( $@ ){ #report any problems
          warn " >Regex problem: appending value sequence against $fname:$@\n" if (!$silent); 
          return "";
     }
  }#end elseif
  
 return $fname;
} #end _sequential($)


sub formatSize($) { #find the filesize format type of a file: b, kb, mb, etc. Parameter = $fileSize_in_bytes 
# return's a list of (size, formatType), "size formatType"
# source, but modified to meet needs: https://kba49.wordpress.com/2013/02/17/format-file-sizes-human-readable-in-perl/
 my ($size, $exp, $units) = (shift, 0, [qw(B KB MB GB TB PB EB ZB YB BB GPB)]);
 return "?" if ($size eq "");

  for (@$units) {
       last if $size < 1024;
       $size /= 1024;
       $exp++;
  }
  
 return wantarray ? (sprintf("%.2f", $size), $units->[$exp]) : sprintf("%.2f %s", $size, $units->[$exp]);  
} #end formatSize($)


sub mySort(@) { #case insensitive sort: sort a list of files Parameter = @files
  return sort { "\L$a" cmp "\L$b" } @_;
}#end mySort(@)


sub fRename($) { #file renaming... only call this when not crawling any subfolders. Parameter = $folder_to_look_at
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

   if ($dryRun && !$noSort){ 
        my %seen = ();
        my @uniquFiles = grep { ! $seen{$_} ++ } @files; #purge duplicate files in list
        foreach ( mySort(@uniquFiles) ){ _rFRename($_); } 
   }else{ 
        foreach ( @files ){ _rFRename($_); } 
   }

  return 1; 
} #end frename($)


sub _processFRename(%) { # sort hash of files then process files Parameter = (%) Hash ->$hashFile{$directory} = @filenames
# Driver for changing sorted file locations/names and launch processing filenames
 my (%hashFiles) = @_; 
 my $lastDir = Cwd::getcwd() . ""; 
    #use Data::Dumper; warn Dumper(@_); print "\%hash\n"; print Dumper(%hashFiles); exit 0;

    chdir ($lastDir) if ( -d $lastDir); #first case
    #sort through hash by directory key and filename array, change locations and call the file process driver on each file
    my @fvalues; 
    for my $dir (mySort(keys %hashFiles)){ 
        my %seen = ();
        @fvalues = grep { ! $seen{$_} ++ } (mySort( @{ $hashFiles{$dir} } )); #sort and purge duplicate files in the list
        
        #@fvalues uniqu = grep { ! $seen{$_} ++ } @list;
        chdir ($dir) if ($dir ne $lastDir); #if directory changed
        foreach (@fvalues){ _rFRename($_) if ($_ ne "." || $_ ne ".."); }  #process filename
        $lastDir = $dir;
        @fvalues = undef; #reset
    }
}#end _processFRename(%)

sub _lock ($) {  #Parameter = expects a filehandle reference to lock a file
  my ($FH)=@_;
   until (flock($FH, LOCK_EX)){ sleep .10; }
}#end _lock($)


sub _unlock($) { #Parameter = expects a filehandle reference to unlock a file
 my ($FH)=@_;
   until (flock($FH, LOCK_UN)){ sleep .10; }
}#end _unlock($)


sub _rFRename($) { 	#recursive file renaming processing. Parameter = $filename
  my ($fname) = @_;
  
   #if true discard the filename, else keep it
   return if( $fname=~m/^(\.|\.\.|\.DS_Store)$/ or                    #if a dot file or macOS .DS_Store
             ($extension and $fname !~m/(\.$extension)$/i) or         #discard all non-matching filename extensions
             ($idir && -d $fname) or (-d $fname && $renameFile)       #if ignore changing folder-names    
            );                                                        #if yes to any, then move along
   if ( !(-w $fname) ) {                                              #if not writable, then move along
        print " --> " . Cwd::getcwd() . SLASH . "$fname is not writable/findable. Skipping file: file or folder changed!\n" if (!$silent);
        return;
   }
   
   my $fold = $fname;                                                 #remember the old name and work on the new one
   my $trans = $transU+$transD+$transWL;                              #add the bools together.. to speed up comparisons

   #apostrophe bug fix: ’ and ' are similar treat them as the same
   $fname =~ tr/’/'/d if ( $matchString eq "'" && $fname =~m/’/ && !$noSanitize );

   if($rx || $rs || $fname=~m/$matchString/ || $trans || ($timeStamp or $sequentialAppend or $sequentialPrepend)){ #change name if
	    if($renameFile){  #replace each file name with the same name with a unique number added to it
	 	     #ex: foo_file.txt  -->  foobar 01.txt, foobar 02.txt, ... foobar n.txt
	 	     return if( $matchString ne "" && not $fname=~m/$matchString/ ); 
	 	     my $r = _sequential($fname);
 	 	     return if ($r eq "");  #next file if if blank current filename is either a folder or failed to append or prepend number	 
 	 	     $fname = $r;
 	    }elsif($rx){ #using regex for translation: example where f='s/^(foo)gle/$1bar/'  or f='y/a-z/A-Z/'  or f='s/(foo|foobar)/bar/g'	
		     $_=$fname if !$rs;
		     eval $matchString;
		     if ($@){ warn " >Regex problem against file name $fname: $@s\n" if (!$silent); }
		     else { $fname = _translate($_) if ($fname ne $_); } #if the name was changed, next try translation	
	    }else{  #all other cases that are not using Regex
		      if ( ($matchString eq "" && $trans) or $fname=~m/$matchString/ ){
              if ( not ($matchString eq "" && $trans) && 
                   not ($replaceMatchWith eq "" and ($sequentialAppend or $sequentialPrepend) ) ){
                   eval $fname=~s/$matchString/$replaceMatchWith/g; 
                   if ($@){ warn " >Regex problem against $fname:$@\n" if (!$silent); return; }
              }
              $fname = _translate($fname) if($trans);
			    
              if ( $sequentialAppend or $sequentialPrepend or $timeStamp ) {
                   my $r = _sequential($fname);
                   return if ($r eq "");  #next file if blank since current filename is either a folder or failed to append or prepend number	 
                   $fname = $r;
              }
          }
      }
      
      return  if $fold eq $fname;                                              #nothing has changed-- ignore quietly

      my ($size, @sizeType) = ("", ());
      if (($dryRun || $verbose) && !$silent){  #gather file meta-data for displaying
          $size = (stat($fold))[7];                                            
          $size = 0 if (! defined $size);                                      #fixes rare bug when existing file data fails to return from stat
          return if ( $targetFilesize and $size < $targetFilesize );           #if filesize too small
          @sizeType = formatSize($size . ""); undef $size;
          return if ( $targetSizetype and ($sizeType[1] ne $targetSizetype) ); #filter out files that don't match size format type
      }

      if ( !$force  && ($confirm || -e $fname) ) {### does a file exist with that same "new" filename? should it be overwritten?
         ### mode to also show file size and age of current existing file
         return if ($noForce);	#dont want to force changes?
         if ( -e $fname ){ print">Transformation: the following file already exists-- overwrite the file? $fname\n  --->"; }
         if ( !confirmChange($fold,$fname,@sizeType) ){ print " -->Skipped: $fold\n" if ($verbose && !$silent); return; }
      } #end does file exist with the same new filename
	 
      if ($dryRun) { #dry run mode: display what the change will look like, update count then return
          ++$fcount;
          print " Change " . getPerms($fold) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t" . "\"$fold\" to \"$fname\"\n" if (!$silent); 
          return;
      }elsif( open (my $FH,, $fold) ){ #lock, rename, and release the file
          _lock($FH); 
          eval { rename ($fold, $fname); };  #try to rename the old file to the new name
          if ($@){ warn " >File rename error $fname: $@\n" if (!$silent); return; }
          _unlock($FH);
          close $FH;
      }
	 	 
      if($@) { #where there any write to file errors?
          warn "ERROR-- Can't rename " . Cwd::getcwd() . SLASH . "\n\t\"$fold\" to \"$fname\": $!\n" if  (!$silent);
      }elsif( $verbose ){
          print " Updated " . getPerms($fname) . " " . Cwd::getcwd() . SLASH . " " . join ("", @sizeType) . "\n\t" . "\"$fold\" to \"$fname\"\n"; 
          ++$fcount;
      }else{ ++$fcount; }
	 
   }#end change filename if clause
 return;   
} #end _rFRename($;$)


sub intoBytes($) { #Parameters = $"filesize+unitType" example 8.39GB, returns size in bytes or -1 if fails
 my ($size) =@_;
#  byte      B
#  kilobyte   KB  = 2**10 B = 1024 B
#  megabyte   MB  = 2**20 B = 1024 * 1024 B
#  gigabyte   GB  = 2**30 B = 1024 * 1024 * 1024 B
#  terabyte   TB  = 2**40 B = 1024 * 1024 * 1024 * 1024 B
#  petabyte   PB  = 2**50 B = 1024 * 1024 * 1024 * 1024 * 1024 B
#  exabyte    EB  = 2**60 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  zettabyte  ZB  = 2**70 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  yottabyte  YB  = 2**80 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  brontobyte BB  = 2**90 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B
#  geopbyte   GPB = 2**100 B = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 B

  if ($size =~m/([-+]?[0-9]*\.?[0-9]+)\s?(B|KB|MB|GB|TB|PB|EB|ZB|YB|BB|GPB)/i ){ #floating point number & unit-type
      my ($number, $type, $exp, $units) = (abs($1), _makeUC($2), 0, [qw(B KB MB GB TB PB EB ZB YB BB GPB)]);
      return $number if $type eq "B";
      for (@$units){
          if ($type eq $units->[$exp]) {
              foreach (1 .. $exp){ $number = $number * 1024;} #due to rounding errors, loop used instead of exponent 
              return $number;
          }
          $exp++;
      }
  }
  return -1;
}#end intoBytes($)


sub findDupelicateFiles() {
#------------------------------------------------------------
# Based off of dupfinder v1: find duplicate files 
# Source: http://www.perlmonks.org/?node_id=224748
#------------------------------------------------------------
# Copyright Antonio Bellezza 2003
# mail: antonio@beautylabs.net
# Adapted by Jason Campisi 2015
#------------------------------------------------------------
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation;
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#------------------------------------------------------------
=begin comment
Note: The goal is to reduce file reading to a bare minimum. Say you have two 1 Gbyte files. 
The size is exactly the same, but the files are very different. I wouldn't want to read 
and digest both files to understand they are different, when it's enough to read a few 
bytes in the same position. This code deals rather well with these cases. It starts by 
reading a small chunk from all files of the same size and uses that chunk as key to 
partition the group of files. If any subset contains more than one file, then read 
another chunk starting from another (preferably far) position and iterate.

It's more or less like the naif "real life" way of comparing things. If you have two books 
with a blank cover, to check if they are different you first compare the size. If it's the 
same, you open the same page from both and check if they differ. Only if the books are the 
same you need to keep on reading until the end.

Moreover, by using byte by byte comparison instead of hashing, you don't even risk false 
positives. As small as the risk may be, it will most surely happen for your presentation 
due tomorrow.

Package Finder::Looper takes care of the iteration. Each call to 
$looper->next returns a new pair ( start, length ) within a given range, so that consecutive 
calls sample from different parts of the file. That's the "interlaced" part (which I should 
maybe have called "interleaved", but hey! this side of the world it's not the best time 
for choosing names in foreign languages).'
=end comment
=cut

my $finder = Finder -> new( $startDir );
my @group = $finder -> findDuplicates();

# Result printout and elaboration!
  for my $group ( @group ) {
     print "Duplicates: size " . formatSize($group->[0]{size}) . "\n";
     for (1..$#$group) { print " [$_] " . getPerms($group->[$_]) . " " . $group->[$_] . "\n"; }
     
     if ($dryRun){ #skip asking which files to keep and don't delete duplicates 
        ++$fcount;
        next;
     }  
     
     my $input ="";
     if ($force){      #don't ask which files to keep, just use the 1st one.
        $input=1; 
     }else{
        print "Action: Press [Return] to skip or choose one file to keep [1-$#$group]\n";
        $input = <STDIN>;
        chomp $input;
        next if $input eq '';
     }
     if ($input =~ m|([0-9]+)| && $1 > 0 && $1 <= $#$group) {
        for (0..($1-1), ($1+1)..$#$group) {
           my $delendum = $group -> [$_];
           print "Unlinking $delendum: ";
           unlink $delendum;
           print " --> done\n";
        }
     }
     print "\n";
  }
}#end findDupelicateFiles()


sub _untaintData ($$) {	#dereference any reserved non-word characters. Parameter = string of data to untaint, flag
 	#flag: >0 run through all filters, <=0 omit some filters
 my ($flag,$s)= (pop @_, ""); ($_)=@_;

  foreach (split //, $_) {		#tokenize and massage special characters
    if (/^(\W)$/){
       if ($1 eq "("){ $_ =qw(\\\(); }
       elsif ($1 eq ")"){ $_ =qw(\\\)); }
       elsif ($1 eq "\^" && $flag){ $_ =qw(\\^); }
       #elsif ($1 eq "\'" && $flag){ $_ = "\N{U+0027}"; } #<-- unicode for Apostraphe
       elsif ($1 eq "\’" && $flag){ $_ =qw(\\'); }   #convert ’ to '
       elsif ($1 eq "\$" && $flag){ $_ =qw(\\$); }
       elsif ($1 eq "\+" && $flag){ $_ =qw(\\+); }
       elsif ($1 eq "\*" && $flag){ $_ =qw(\\*); }
       elsif ($1 eq "\?" && $flag){ $_ =qw(\\?); }
       elsif ($1 eq "\[" && $flag){ $_ =qw(\\[); }
       elsif ($1 eq "\]" && $flag){ $_ =qw(\\]); }
       elsif ($1 eq "\." && $flag){ $_ =qw(\\.); }
       elsif ($1 eq "|"  && $flag){ $_ =qw(\\|); }
       elsif ($1 eq "\\"){ $_ ="\\" . "\\";}
       elsif ($1 eq "/"){ $_ =qw(\\/);}
       elsif ($1 eq "\!" && $flag){ $_ =qw(\\!); }
	  }
	  $s.=$_;  #put the chars back together into word(s)
  }#end foreach
  return $s;
}#end _untaintData($)

sub untaintData() {					#sanitize provided input data
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
	 print "-->Targeting only files of at least size $targetFilesize -> " . intoBytes($targetFilesize) ." bytes\n" if($targetFilesize);
	 print "-->Confirm changes\n" if($confirm);
	 print "-->Force changes\n" if($force);
	 print "-->Don't overwrite files\n" if($noForce);
	 print "-->Target extension $extension\n" if($extension);
	 print "-->Regular expression mode\n" if($rx);
	 print "-->Case-Translate Upper-to-Lower\n" if($transD);
	 print "-->Case-Translate Lower-to-Upper\n" if($transU);
	 print "-->Delete .DS_Store files\n" if($dsStore);
	 print "-->Case-Translate 1st letter per word to uppercase\n" if($transWL);
	 print "-->Sequential file count: append number to file name\n" if($sequentialAppend);
	 print "-->Sequential file count: prepend number to file name\n" if($sequentialPrepend);
 	 print "-->Timestamp in name\n" if ($timeStamp);
 	 print "-->Find Duplicate files\n" if ($duplicateFiles);
	 print "-->Name all files as $renameFile\n" if($renameFile);
 	 print "-->Start count=$startCount\n" if ($startCount);
	 print "-->Recursively traverse folder tree\n" if ($rs);
	 print "-->no sorting files\n" if ($noSort);
	 print "-->Dry run test\n" if($dryRun);
	 print "-->Verbose option\n" if($verbose);
	 print "-"  x 55 . "\n";
	 print "Locations:\n" if (!$duplicateFiles);
   }else { untaintData(); }
}#end showUsedOptions()

sub prepData() {  # prep Data settings before the program does the real work.
   $force++ 		if $silent; #if silent-mode is on, then activate force-mode
   $noSanitize++ 	if $rx;	#don't treat regular expressions

   if (! -d $startDir ){
       if(!$silent and $force or ask("|Error: \'$startDir\' is not a valid folder!\n| Do you want to use your current location instead? ") ){
           $startDir=Cwd::getcwd();
           print "|Start location changed to: $startDir\n" if ($verbose);
       }else{ exit; }           
   }

   showUsedOptions();
     
   if ($dsStore) { #purge .DS_Store files in macOS
       use English qw' -no_match_vars ';
       if ( $OSNAME eq "darwin" ){ #target only macOS
           print "Purging .DS_Store files at $startDir\n" if (($dryRun || $verbose) && !$silent);
           qx\find "$startDir" -name .DS_Store -type f -delete\;
       }
   }
   
   return if ($duplicateFiles); #if true nothing to prep

   if ($renameFile ne ""){ #if -rf mode ensure Append/Prepend is set too
       if (($sequentialAppend eq 0 && $sequentialPrepend eq 0) or
       	   ($sequentialAppend && $sequentialPrepend) ){ #if both flags not set or both selected set to append
           $sequentialAppend = 0;  # add the end of name
           $sequentialPrepend = 1; # add to the beginning
       }
       $rs = 0 if ($noSort); #disable, since it does not reset the number-count when going into each new folder
   }elsif (!$timeStamp && $sequentialAppend or $sequentialPrepend) { #if -sa or -sp disable -r mode
       $rs = 0 if ($noSort); #disable, since it does not reset the number-count when going into each new folder 
   }elsif ($timeStamp && $sequentialAppend){
   		$sequentialPrepend = 0;
   }elsif ($timeStamp){
   	   $sequentialPrepend = 1;
   }
   
   if (($force and $renameFile) or ($renameFile and $extension and !($renameFile =~m/$extension$/i)) and 
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
       $targetSizetype = "" if ($targetSizetype !~m/(B|KB|MB|GB|TB|PB|EB|ZB|YB|BB|GPB)/i);
   }
   if ($targetFilesize){
       if ($targetFilesize !~m/(B|KB|MB|GB|TB|PB|EB|ZB|YB|BB|GPB)/i) { $targetFilesize = "";}
       else { $targetFilesize = intoBytes($targetFilesize); } #only use this info comparing bytes so convert
   } 
   
}#end prepData()


sub main() {
  #Setup settings and messages
   cmdlnParm() 	    if ($version || $help || ($matchString eq "" && 
                       (!$transU && !$transD && !$transWL && !$renameFile &&
                        !$timeStamp && !$sequentialAppend && !$sequentialPrepend &&
                        !$duplicateFiles && !$dsStore))
                    );
   prepData();

 #Everything is setup, now start looking for files to work with
   if ($duplicateFiles){
       findDupelicateFiles();
   }elsif ( ($dryRun && !$noSort) && ($rs || $fs) ){ #Sort only dryRun mode & recursively traverse the filesystem?
       my %hashFiles = (); # $hashFile{$directory} = @filenames Hash of file location keys that point to arrays of file names 
       if ($fs) { #follow symbolic links? 
            File::Find::find( {wanted=> sub { push(@{ $hashFiles{Cwd::getcwd() . ""} }, "$_"); }, follow=>1} , $startDir ); 
            #use Data::Dumper; print "follow sorted sym links mode\n"; print Dumper(%hashFiles); #exit 0;
            _processFRename( %hashFiles ); #process file tree
       }else{ # recursive
            File::Find::finddepth( sub { push(@{ $hashFiles{Cwd::getcwd() . ""} }, "$_"); }, $startDir ); #build a file tree
            #use Data::Dumper; print "follow recursive sort\n"; print Dumper(%hashFiles); exit 0;
            _processFRename( %hashFiles ); #process file tree
       } #follow folders within folders
   }elsif ($rs){ #no sort recursively traverse the filesystem?
       if ($fs) { File::Find::find( {wanted=> sub {_rFRename($_);}, follow=>1} , $startDir ); } #follow symbolic links? Can't sort with follow flag
       else{ File::Find::finddepth( sub {_rFRename($_);}, $startDir ); } #follow folders within folders
   }else{ fRename($startDir); }  #only look at the given base folder
     
   if(!$silent && $dryRun or $verbose){
       print "-"  x 55 . "\n";
       #does the file-count need converting?
       if (($sequentialAppend or $sequentialPrepend) && $startCount > 0) { 
           $fcount = ($fcount - $startCount) + 1;
       }
       my $msg="";
       if($dryRun){ 
            if($duplicateFiles){ $msg="Total Duplicate Sets Found"; }
            else { $msg="Purposed Files To Change"; }
       }else{ $msg="Files Changed"; }
       print "Total " . $msg . ": $fcount\n";
   }
 exit 0;
}#end main()

main();		#run the code
	
	
#------------------------------------------------------------
# Below are the supporting parts of findDupelicateFiles() aka dubFinder.pl 
# Copyright Antonio Bellezza 2003 GPL2 
# readDirs($) modified by Jason Campisi 2016
#------------------------------------------------------------
package Finder;

#------------------------------------------------------------
# A finder is implemented as a hash
# $finder -> {groups} is the array of groups of possibly
# equal files
# Each group is an array whose first element is a hash
# with the various key attributes.
# Subsequent elements are the filenames in the group
# Example:
# [
#   [ { size=>0 }, 'empty.txt', 'null.dat', 'nothing_here' ],
#   [ { size=>1321, hash12=>'xyz' }, 'myfile.a', 'myfile.b' ],
#   [ { size=>1321, hash12=>'wtt' }, 'myfile.c', 'myfile.d' ]
# ]
#------------------------------------------------------------

use strict;
use IO::File;
use File::Find;

use constant MINREADSIZE => 1024;
use constant MAXREADSIZE => 1024 * 1024;
use constant BLOCK   => 4096;

our $handles = {};


#----------------------------------------
# new ( dir, ... )
# Create new finder
#----------------------------------------
sub new {
  my $class = shift;
  my $self = {
    dirs     => [ @_ ],
    groups   => [],
    terminal => []
  };
  return bless $self, $class;
}

#----------------------------------------
# readDirs ()
# Find all files and setup finder
#----------------------------------------
sub readDirs {
  my $self = shift;
  if ($extension){ # Seek out filenames with fileType X, only
     my @group;
     my $newGroup=[{}];
     find( sub { -f && ( push @group, $File::Find::name ) }, @{$self->{dirs}} );
     foreach (@group){ push @$newGroup, $_ if $_ =~m/\.$extension$/i; }
     $self -> {groups} = [ $newGroup ];
  } else { #grab all filenames
     my $group=[{}];
     find( sub { -f && ( push @$group, $File::Find::name ) }, @{$self->{dirs}} );
     $self -> {groups} = [ $group ];
  }  
    
}#end readDirs


#----------------------------------------
# findDuplicates()
# Return list of terminal groups
#----------------------------------------
sub findDuplicates {
    my $self = shift;
    my $hasher;
    $self -> readDirs();

#    print $self -> status;

    $hasher = { process  => \&size,
        name     => 'size',
        terminal => sub { shift==0 } };

    $self -> {groups} = [ $self -> partition( $self -> {groups} [0], $hasher ) ];

#    print $self -> status;

    $self -> prune();

#    print $self -> status;

  for( @{$self -> {groups}} ) {
     my @processList = ( $_ );
     my $size = $_ ->[0]{size};
     my $iterator = Finder::Looper -> new( $size );

     while ( @processList and my ( $start, $length ) = $iterator -> next() ) {
          $hasher = { process => \&sample,
                    args => [ $start, $length ] };
          my @newList = ();
          for (@processList) {
              my @subgroup = ( $self -> partition( $_, $hasher ) );
              $self -> prune( \@subgroup );
              push @newList, @subgroup;
          }
          @processList = @newList;
     }
     closeHandles( @processList );
     $self -> addTerminal( @processList );
     
  }
  return @{ $self -> {terminal} };
}#end findDuplicates



#----------------------------------------
# prune ()
# prune ( \@group )
# Remove groups only containing one file
# If argument is omitted, remove from $self -> {groups}
# Add to terminal groups with terminal key
# Return number of remaining groups
#----------------------------------------
sub prune {
 my $self = shift;
 my $src = $_[0] || $self -> {groups};
 my $counter = 0;
 
  for ( my $i = $#$src; $i>=0; $i--) {
        my $group = $src -> [$i];
        if ( $group -> [0] {terminal} ) {
            # Remove and add to terminal groups
            $self -> addTerminal( $group );
            closeHandles( $group );
            splice @$src, $i, 1;
        } elsif ( $#$group > 1 ) {
            # Keep in place
            $counter ++;
        } else {
            # Drop group only containing one file
            closeHandles( $group );
            splice @$src, $i, 1;
        }
  }
    return $counter;
}


#----------------------------------------
# partition( $group, hasher [, hasher par, ... ] )
# Execute a discriminatory step and create subgroups
# Return list of groups
# A hasher is a hash ref of type
# {
#    process  => sub { taking fileName as first arg, key as second argument },
#    name     => hash-key name / undef if not added,
#    terminal => sub { shift is a terminal key or not },
#    args     => [ extra arguments to pass ]
# }
#----------------------------------------
sub partition {
    my $self = shift;
    my ($group, $hasher, @hasherPar) = @_;

    my $key = shift @{$group};
    my %bucket = ();

  for (@{$group}) {
     my $hash = $hasher -> {process} -> ($_, $key,
                        @{ $hasher -> {args} || [] },
                        @hasherPar);
     push @{ $bucket {$hash} ||= [] }, $_;
  }

  my @result = ();

  for (keys %bucket) {
    # Create a clone of the key
     my $newKey = { %$key };
     $newKey -> { $hasher -> {name} } = $_ if $hasher -> {name};
     $newKey -> {terminal} = 1
     if ( $hasher -> {terminal} && $hasher -> {terminal} -> ($_) );
     push @result, [ $newKey, @{$bucket {$_}} ];
  }

    return @result;
}


#----------------------------------------
# status()
# Return string showing finder status
#----------------------------------------
sub status {
  my $self = shift;
  my $res = 'Groups:';
   for (grep {$_ > 0} map {$#$_} @{$self -> {groups}}) { $res .= " $_"; }

   $res .= "\nTerminal:";
   for (grep {$_ > 0} map {$#$_} @{$self -> {terminal}}) { $res .= " $_"; }
   $res .= "\n";
  return $res;
}


#----------------------------------------
# function
#----------------------------------------
# fileHandle( filename )
# return fileHandle or undef
#----------------------------------------
sub fileHandle {
  my ($fileName) = @_;
    
  unless ($handles -> {$fileName}) {
    my $handle = IO::File -> new();
    $handle -> open("<$fileName") || return undef;
    $handles -> {$fileName} = $handle;
  }
  return $handles -> {$fileName};
}

#----------------------------------------
# function
#----------------------------------------
# closeHandle( filename )
# close handle
#----------------------------------------
sub closeHandle {
    my ($fname) = @_;
    delete $handles -> {$fname};
}

#----------------------------------------
# function
#----------------------------------------
# closeHandles( $group, ... )
# Close handles of filenames contained in group
#----------------------------------------
sub closeHandles {
  for my $group (@_) {
     for (1..$#$group) {
        closeHandle( $group -> [$_] );
     }
  }
}

#----------------------------------------
# addTerminal( \@file, ... )
# Add to terminal sets arrays of files with given size
#----------------------------------------
sub addTerminal {
    my $self = shift;
    push @{ $self -> {terminal} }, @_;
}

{
    my $error = 0;

#----------------------------------------
# sample ( filename, key [, start [, length ] ] )
#----------------------------------------
 sub sample {
    my ($fname, $key, $start, $length) = @_;
    $start ||= 0;

    my $res;

    # Return a consecutive error code if unable to open file
    my $handle = fileHandle( $fname ) || return "Error " . $error++;
    $handle -> seek( $start, 0 );

    if ($length) {
        $handle -> read( $res, $length );
    }else {
       $res = '';
       my $buffer;
       while ( $handle -> read( $buffer, BLOCK ) ) { $res .= $buffer; }
    }
    return $res;
 }
}


#----------------------------------------
# size ( filename )
# Find file size
#----------------------------------------
sub size {
    my $fname = shift;
    return (stat ($_))[7];
}


#------------------------------------------------------------
# Finder::Looper
#------------------------------------------------------------
# Iterator providing starting points and lengths
# for interlaced reads
#------------------------------------------------------------
package Finder::Looper;

use constant MINREADSIZE => Finder::MINREADSIZE;
use constant MAXREADSIZE => Finder::MAXREADSIZE;
use constant BLOCK       => Finder::BLOCK;


#----------------------------------------
# new( size [, minsize [, maxsize ]] )
#----------------------------------------
sub new {
 my $class = shift;
 my ( $size, $minsize, $maxsize ) = @_;
  $minsize ||= MINREADSIZE;
  $maxsize ||= MAXREADSIZE;
  bless {
    size     => $size,
    minsize  => $minsize || MINREADSIZE,
    maxsize  => $maxsize || MAXREADSIZE,
    readsize => $minsize || MINREADSIZE,
    oldsize  => 0,
    i        => 0,
    gap      => 1 << nextLog2( $size )
  }, $class;
}

#----------------------------------------
# next()
# return ( start, length )
# return () if the iteration is over
#----------------------------------------

sub next {
  my $self = shift;

  # Return EOL if the gap has become smaller than the size
  # unless it's the first iteration ( oldsize = 0 )
  if ( $self -> {readsize} > $self -> {gap} && $self -> {oldsize} > 0 ) {
    return ();
  }
    
  if ( $self -> {i} * $self -> {gap} >= $self -> {size} ) {
    $self -> {i} = 0;
    $self -> {oldsize} = $self -> {readsize};
    $self -> {gap} >>= 1;
    $self -> {readsize} <<= 1
        if ( $self -> {readsize} < $self -> {gap}
         && $self -> {readsize} < $self -> {maxsize} );
  }

  my $offset = ( $self -> {i} % 2 ) ? 0 : $self -> {oldsize};
    
  my $start  = $self -> {i} * $self -> {gap} + $offset;
  my $length = $self -> {readsize} - $offset;
  $length    = $self -> {size} - $start if $start + $length > $self->{size};

  $self -> {i} ++;

  if ( $length <= 0 ) {
    return $self -> next();
  } else {
    return ( $start, $length );
  } 
}

#----------------------------------------
# function
#----------------------------------------
# nextLog2( positive integer )
# return exponent of nearest power of 2
# not less than integer
# Warning: returns at most the biggest power of
# two expressed by an integer
#----------------------------------------
sub nextLog2 {
  my ($i, $pow, $exp) = (shift, 1, 0);

  while ( $pow < $i && $pow > 0 ) {
    $pow <<= 1;
    $exp++;
  }
  return $exp;
}	
	

__END__
