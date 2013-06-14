#!/usr/bin/perl -w
#!perl
############
##Author Jason Campisi
##File: FilePerms.pm v0.1
##Date: 2.15.2008
##EULA: GPLv2 or higher { http://www.fsf.org/licensing/licenses/info/GPLv2.html }
package FilePerms;
use strict;
use warnings;

sub BEGIN { 
   if ($^O=~m/win/i){
  	eval{
    			require Win32::File;
#     			Win32::File->import(qw(READONLY ARCHIVE));
  	};
   }
}#end BEGIN

sub getWinPerms($){
my ($filename)=@_; 
	return getUnixPerms($filename);

return "???" unless (
     $^O =~ m/Win32/                  &&    # we're on Win32
     -f $filename);

# # R  	 User is allowed to open the object for reading.
# # r 	User is not allowed to open the object for reading.
# # W 	User is allowed to open the file for writing.
# # w 	User is not allowed to open the file for writing.
# # D 	User is allowed to delete the object.
# # d 	User is not allowed to delete the object.
# # X 	User is allowed to execute the object. When this permission is applied to a directory or Registry key, the user is allowed to access its contents.
# # x 	User is not allowed to execute the object. When this permission is applied to a directory or Registry key, the user is not allowed to access its contents.
# # P 	User is allowed to change the object's permissions.
# # p 	User is not allowed to change the object's permissions.
# # O 	User is allowed to take ownership of the object.
# # o 	User is not allowed to take ownership of the object.
# # A 	User has been granted all permissions. This permission may be set in addition to other flags.
# # a 	User has been denied all permissions. This permission may be set in addition to other flags.

# my  %perm = ( 'R'   =>  1,  'W'   =>  2,  'X'   =>  3, 'D'   =>  4,  'P'   =>  5,  'O'   =>  6,  'A'   =>  7, );
# 
# #http://www.codeproject.com/KB/books/1578702151.aspx
# #What does a return code of "-1" mean?  File not found
# my ($attr, $attr_decoded)=("","");
# Win32::File::GetAttributes( $filename, $attr );
# 
#  $attr_decoded .= "r" if ($attr & READONLY);# { print "$filename Read Only\n" }
#  $attr_decoded .= "d" if ($attr & DIRECTORY);# { print "$filename Directory\n" }
#  $attr_decoded .= "h" if ($attr & HIDDEN);# { print "$filename Hidden\n" } 
#  $attr_decoded .= "s" if ($attr & SYSTEM);
#  $attr_decoded .= "a" if ($attr & ARCHIVE);
#  $attr_decoded .= "e" if ($attr & ENCRYPTED);
#  $attr_decoded .= "n" if ($attr & NORMAL); 
#  $attr_decoded .= "t" if ($attr & TEMPORARY);
#  $attr_decoded .= "c" if ($attr & COMPRESSED);# { print "$filename Compressed\n" } 
#  
# 


# 			FILE_ATTRIBUTE_READONLY =>             0x00000001,
# 			FILE_ATTRIBUTE_HIDDEN =>               0x00000002,
# 			FILE_ATTRIBUTE_SYSTEM =>               0x00000004,
# 			FILE_ATTRIBUTE_DIRECTORY =>            0x00000010,
# 			FILE_ATTRIBUTE_ARCHIVE =>              0x00000020,
# 			FILE_ATTRIBUTE_ENCRYPTED =>            0x00000040,
# 			FILE_ATTRIBUTE_NORMAL =>               0x00000080,
# 			FILE_ATTRIBUTE_TEMPORARY =>            0x00000100,
# 			FILE_ATTRIBUTE_SPARSE_FILE =>          0x00000200,
# 			FILE_ATTRIBUTE_REPARSE_POINT =>        0x00000400,
# 			FILE_ATTRIBUTE_COMPRESSED =>           0x00000800,
# 			FILE_ATTRIBUTE_OFFLINE =>              0x00001000,
# 			FILE_ATTRIBUTE_NOT_CONTENT_INDEXED =>  0x00002000,

#http://www.perl.com/doc/FAQs/nt/perlwin32faq4.html

#for win9x
#Win32 systems inherit from DOS four possible file attributes: archived (A), read-only (R), hidden (H), and system (S). These can be checked and set with the Win32::File::Get/SetAttributes().

#Windows NT systems using NTFS can also have more specific permissions granted on individual files to users and groups. For builds 300 and above, and the Perl Resource Kit for Win32, you can use the Win32::FileSecurity module to maintain file permissions.



# http://www.xav.com/perl/lib/File/stat.html

#  my $sb;
#     use File::stat;
#     if($sb = stat($file) ){
# #     	return sprintf "File is %s, size is %s, perm %04o, mtime %s",  $file, $sb->size, $sb->mode & 07777, scalar localtime $sb->mtime;
#  	return sprintf "perm %04o, size is %s, mtime %s\n",  $sb->mode & 07777, $sb->size, scalar localtime $sb->mtime;
#    }
#    return "???";

}#end _getWinPerms

sub getUnixPerms($){
my ($file)=@_; 
 return "???" unless (-e $file && (-f $file || -d $file || -c $file) ); #does it exist? is a directory or file?
 my @perm=split "",sprintf "%04o", (lstat($file))[2] & 07777;	#mask off the file type portion to see the real permissions
 my @per=("---","--x","-w-","-wx","r--","r-x","rw-","rwx");  #for decyphering file permission settings

# d - - -		= directory
# l  - - -		= symbolic link
# c - - -		= special character file
#    - - - (or 0) = no permission
#    r - - (or 4) = read-only permission
#    rw - (or 6) = read/write permission
#    rwx (or 7) = read/write/execute permission

  if(-l $file){$file="l";} 		#symbolic link?
  elsif(-d $file){$file="d";}	#directory?
  elsif(-c $file){$file="c";}	#special character file?
  else{$file="-";}			#normal file
 return $file . $per[$perm[1]] .$per[$perm[2]] . $per[$perm[3]] ;	#return owner,group,global permission info 
}#end _getUnixPerms

return 1;

sub END { }

__END__