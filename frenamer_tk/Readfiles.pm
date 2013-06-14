#!/usr/bin/perl -w
#!perl
############
##Author Jason Campisi
##File: Readfile.pm v0.1
##Date: 2.15.2008
##EULA: GPLv2 or higher { http://www.fsf.org/licensing/licenses/info/GPLv2.html }
package Readfiles;
use strict;
use Fcntl  ':flock'; # import LOCK_* constants;
use warnings;

# HoA: data is stored using this construct
# #  %self = (
# #         manual     => [ "location", "about_filedata" ],
# #         gpl            => [ "location", "gpl_filedata" ],
# #         regrex      => [ "location", "tutorial_filedata" ],
# #   );

sub new (;%){#optional hash of filename locations and keyword 
my($self, %args) = @_;
    $self={};
    bless($self); 
    if (scalar keys %args){	#load any possible keyword / files_locations 
 	setFilename($self, %args);
    } 
  return $self;
}#end new()

sub DESTROY{ #object destructor
   deleteAll(@_);	#destory all stored information in the anonymous hash of array
}#end DESTROY

sub checkFilename($){
   shift; #class
   return _checkFilename((shift)); #filename
}#end checkFilename

sub _checkFilename($){#checks to see if does it exist and is it readable.   Param: a string of filename and path to it. Return bool
 my ($f)=@_;
	return 0 if (($f eq "" ) or ( not (defined $f))) ;
    return (( -e $f ) and ( -r $f))  ? 1 : 0;
}#end _checkFilename

sub setFilename(%){# key=>location		#return a list of files that failed to load. but if emptry then no errors
  my($self, %args) = @_;
  my @error;

    foreach my $f (keys %args){
	$args{$f}="" if not defined $args{$f};
 	 if (_checkFilename( $args{$f}) ) {
		$self->{$f}[0]=$args{$f};
 	}
 	else{ $error[ $#error++] = "Error finding this file: tag \"$f\" --> " . $args{$f};  }
    }
#  return (scalar @error >0) ? undef : @error;
  return @error;
}#setFilename

sub _lock ($){#expects a filehandle reference
  my ($FH)=@_;
   until (flock($FH, LOCK_EX)){ sleep .10;}
}#end _lock($)

sub _unlock($) {#expects a filehandle reference
 my ($FH)=@_;
   return 1 if flock($FH,LOCK_UN);
   return 0;
}#end _unlock($)

sub readFile($;$) {#expects a key that points to the  filename string. Returns bool value
#returns true or false value based on whether it was able to read the file
#whether it fails or not-- an error message or data is storaged using that same key 
 my ($self, $filekey)=@_;

return 0 if ( !(exists  $self->{ $filekey } )  or  !(defined $self->{ $filekey }[0] )  );

   if ( open(FH, "<$self->{$filekey}[0]") ) {	#open read-only
	_lock(\*FH);
	{#read a file very quickly: enclose to localize only the following change
		local $/ = undef;	#We set the input record separator to undef, so the entire file is slurped as a single string.
		$self->{$filekey}[1]=<FH>;
	}
	_unlock(\*FH);
	return 1;
   }

  return 0;
}#end  read_file($)

sub getKeys(){#returns an array of keys
  my ($self)=@_;  my @k;
   foreach my $key (keys %{$self}){
 	$k[ $#k++]=$key;
   }
   return @k;
}#end getKeys

sub getFile($){#	Param: filekey and returns a string of the requested file
  my ($self, $filekey)=@_;
	 if (!(exists $self->{ $filekey } and defined $self->{ $filekey }[1]) ){#if file has not already be read, store, and return the filedata
		return readFile($self, $filekey)   ? $self->{$filekey}[1] :  "";		#file has yet to be read and loaded into memory
	}
return $self->{$filekey}[1];	#grab the stored filedata

}#end getFile

sub deleteAll(){	#empty the hash of all data
  my ($self)=@_;
	foreach my $item (keys %{$self}){
		 deleteRecord($self, $item);
	}
}#end deleteAll

sub getFolderList($){#Param=folder_location  returns a list of names of files/folders in a given folder, if empty no files/folders were found
 my ($self, $dir)=@_;
 my @dfiles;

#attempts to handle being called directly:	Readfiles::getFolderList("/home/foo") 
# and as an object: 					$file->getFolderList("/home/foo")
  $dir=$self if not defined $dir;		
  return @dfiles if (not -d $dir);	#if the location is not a valid folder, return
  if( opendir DLIST, $dir){#"."
    	@dfiles=readdir (DLIST);
	closedir DLIST;
  }
  return @dfiles;
}#end getFolderList

sub deleteRecord($){	#remove the record of the keyword,file location, and file data that may be stored under a given keyword-tag
  my ($self, $filekey)=@_;
  return (delete $self->{$filekey})? 1 : 0;
}#end deleteRecord

sub deleteFile($){		#removed the loaded file under a certain keyword tag
  my ($self, $filekey)=@_;
  return ($self->{$filekey}[1]=undef)? 1 : 0;
}#end deleteFile

return 1;
