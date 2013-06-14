#!/usr/bin/perl -w
#!perl
#Author: Jason Campisi
#Date: 2008
#Filename: frenamer_tk.pl
###
####features to add: 
#backup-- choose which to support: either backup all files that are renamed or backup files that would otherwise be overwritten
#dryrun: see what would change without any risks
#number rename with digit incriment. example--say match all files to this pattern or rename all files and rename them thing1..# or 1..#thing
#
####http://w4.lns.cornell.edu/~pvhp/ptk/ptkFAQ.html

#perl -MTk -e 'print $Tk::VERSION."\n"'
# tested on tk 804.027
# Headers
#
use Tk 804;
use Tk::ROText;
# sub Tk::Error {;} #do nothing so that Tk::Error is stopped from reporting   #note:   
use AddDirTk;
# require Tk::ErrorDialog;

use Cwd;
use Getopt::Long;
use File::Find;
use File::Copy;
no warnings 'File::Find';	#disgard STDERR warnings about file permissions and failures related to accessing such things
use Readfiles;
use FilePerms;
use constant SLASH=>($^O=~m/win/i) ? "\\" : qw(/);  #backward SLASH for Window filesystem paths, else unix forward slash
use Data::Dumper;
use warnings;
#
# Global variables
#
my ( # MainWindow
        $WWIDGETS,
        # Hash of all widgets
        %ZWIDGETS,
        #Has of only Top Window Widgets... main window of the program, dialog box, About/Manual windows
        %WWIDGETS,
    );
my ( #program name
	$progn,
	#program version number
	$v,
      )=qw(FrenamerTK 0.2.1);

#readonly file container
my $files=Readfiles->new(		#store locations of files, before the program starts changing directory locations
		'gpl'		=>Cwd::cwd() . SLASH . "gplv2.txt",
		'tutoral'	=>Cwd::cwd() . SLASH . "regrex.txt",
		'manual'	=>Cwd::cwd() . SLASH . "manual.txt",
  ); 


#
# User-defined variables
#

 my ($startDir, $matchString, $replaceMatchWith, $message, $runstopMessage) = ( "", "", "", "", "Run"); 
 my ($verbose) = (1); #switch on by default
 my ($fcount,  $version, $help, $confirm, $force, $noForce, $dryRun, $transD, $transU, $rx, $noSanitize, $rs) = 
		(0,		0,	0,		0,		0,		0,	0,		0,		0,	     0,	0,		0);
my  ($backupMode, $fs, $safeMode, $filetypeMode, $filetype, $batchJobCount) =
         	(0,		  0,		0,		0,			"",		1);

my $isOK = 0; # flag for tracking the confirmFrame Y/N buttons selection where "1" means OK, "-1" means cancelled
my ($bgblue, $textblue, $bglightblue, $bglitewhiteblue) =("\#6fa9e4", "\#08528b", "\#DCE4F9", "\#f1f5fa"); 

 GetOptions( #cmdline options
	   "f=s" =>\$matchString,		"tu" =>\$transU,		"d=s" 	=>\$startDir,
 	   "s:s" =>\$replaceMatchWith,	"td" =>\$transD,		"v"   	=>\$verbose,
 	   "c"   =>\$confirm,	    		"r"  =>\$rs,			"version" =>\$version,
 	   "fs"  =>\$fs,	    				"x"  =>\$rx,			"help"	=>\$help,
 	   "y"   =>\$force,				"n"  =>\$noForce,		"sm"	=>\$safeMode,
 	   "ns"  =>\$noSanitize,			"b"  =>\$backupMode, 	"dr"		=>\$dryRun,
	   "ft=s"=>\$filetype,
	);

  $SIG{INT} = sub { 	#capture Ctrl+C signals
   		our $signal=shift; 	die "\n $progn v$v: Signal($signal) ~~ Forced Exit!\n";
 };
#   $SIG{CHLD} = sub {  wait;  };
# $SIG{CHLD} = 'IGNORE';
  $SIG{__WARN__} = sub{   print STDERR "Perl warning: ", @_; };

#sub buildMainWindowGUI{
######################
#
# Create the MainWindow
#
######################
$WWIDGETS{'MW'}= MainWindow->new(
   -background =>$bgblue, 
   -borderwidth=>2,
  );
 #capture the close window x-button press and exit cleanly with no dangling processes
  $WWIDGETS{'MW'}->protocol( 'WM_DELETE_WINDOW' =>\&_closeCleanly); #finding this: research is its own madness sometimes
	## .oO( "Sometimes, women are their own madness!" might make a good tshirt slogon )

## Reserve spots for other top level window keys that will be used
$WWIDGETS{'ABOUT'}="";	#About text window for the manual, EULA, and Regex tutorial
##########################################

#Widget create  menu bar with a help option
my $mbar = $WWIDGETS{'MW'}->Menu(
   -background =>$bgblue,
   -activebackground=>'white',
   -relief => 'flat',
   -borderwidth =>0,
  );
$WWIDGETS{'MW'}-> configure(
   -menu => $mbar, 
   -background =>$bgblue,
   -relief => 'flat',
   -borderwidth =>0,
  );

###make a session menubar

#widget create menu options
my $mbarFile =$mbar-> cascade( -label =>"File", -underline =>0, -tearoff => 0);	#exit menu drop down list
$mbarFile->command(#level 0
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"New",			
   -underline => 0,
   -accelerator => 'Ctrl-N',	
     -command => sub { resetNew(); },
  );

$mbarFile->command(#level 1
   -background=>'white',
   -activebackground=>$bglightblue,
    -accelerator => 'Ctrl-Q',
   -label =>"Quit",				#About option shows the manual
   -underline => 0,
    -command =>\&_closeCleanly, 	#add a close all windows sub function later before saying exit
  );

my $mbarSession =$mbar-> cascade( -label =>"Session", -underline =>1, -tearoff => 0);	#exit menu drop down list
$mbarSession->command(#level 0
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"Add New Folder",			
   -underline => 0,
   -accelerator => 'Alt-A',	
   -command =>\&add_button_event,
  );

# $mbarSession->separator;

$mbarSession->command(#level 1
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"Reset Options",			#have it reset the checkboxes.... ( and input boxes?)
   -underline => 1,
   -accelerator => 'Ctrl-O',	
    -command => sub { _clearOptions();  },	#_clearInput();
  );

$mbarSession->command(#level 2
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"Clear Results",			#have it reset the input boxes   
   -underline => 0,
   -accelerator => 'Ctrl-C',	
    -command => \&_clearOutput,	#clear the ROText box
  );

# $mbarSession->separator;

$mbarSession->command(#level 3	#NOTE NEEDS UPDATE TWEAKING
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"Run Batch Job",	#toggle to say Stop Batch Job when the Run button is pressed 		
   -underline => 0,
   -accelerator => 'Alt-R',	#toggle to say Alt-S when the Run button is pressed 
   -command =>\&run_and_stop_button_event,	
  );

#######
 my $mbarHelp = $mbar-> cascade(-label =>"Help", -underline=>0, -tearoff => 0 );	#help menu drop down list
 $mbarHelp->command(#level 0
   -background=>'white',
   -activebackground=>$bglightblue,
   -label =>"Manual",				#About option shows the manual
   -underline => 2,
   -command => [\&_aboutHelpMenu_button, "Manual"],
  );
 $mbarHelp->command(#level 1
   	-background=>'white',
   	-activebackground=>$bglightblue,
	-label =>"Advanced Tutoral",
	-underline=>1, 
	-command => [\&_aboutHelpMenu_button, "Regex"] 
  );#option Regex lession
 $mbarHelp->command(#level 2
   	-background=>'white',
   	-activebackground=>$bglightblue,
	-label =>"Terms of use", 
	-underline=>1, 
	-command => [\&_aboutHelpMenu_button, "EULA"]
  ); #end user license agreement  option


# Widget inputFrame isa Frame
$ZWIDGETS{'inputFrame'} = $WWIDGETS{'MW'}->Frame(
   -background =>$bgblue,
  )->grid(
   -row        => 0,
   -column     => 0,
   -columnspan => 4,
   -sticky     => 'new',
  );

# Widget dirFrame isa Frame
$ZWIDGETS{'dirFrame'} = $ZWIDGETS{inputFrame}->Frame(
   -background  => $bgblue,
   -borderwidth => 0,
  )->grid(
   -row        => 0,
   -column     => 0,
   -columnspan => 4,
   -sticky     => 'w',
  );

# Widget startFolderLabel isa Label
$ZWIDGETS{'startFolderLabel'} = $ZWIDGETS{dirFrame}->Label(
   -background => $bgblue,
   -text       => 'Folder location to hunt for files:',
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'w',
  );

# Widget folderEntry isa Entry
$ZWIDGETS{'folderEntry'} = $ZWIDGETS{dirFrame}->Entry(
   -background   => 'white',
   -foreground   =>$textblue,
   -takefocus    => 1,
   -text =>$startDir,
   -width        => 155,
  )->grid(
   -row        => 1,
   -column     => 0,
   -columnspan => 2,
   -sticky     => 'new',
  );
$ZWIDGETS{'folderEntry'}->configure(	#toggle text color based on if it is a existing folder-name & location, where true=blue & false=red text colour
    -validate        => 'key',
    -validatecommand => sub 
		{#make changing the text works forward and backward when typing-- thus force  both cases vaild
			if(-e $_[0] and -d $_[0]){#does this location exist and is it a directory?
				$ZWIDGETS{'folderEntry'}->configure(-foreground   => $textblue);  #blue color
			}else{
 				$ZWIDGETS{'folderEntry'}->configure(-foreground   => 'red');  #default red color
			}
			return 1;
		},
  );


# Widget addDButton isa Button: purpse is to go get a folder name from the user
$ZWIDGETS{'addDButton'} = $ZWIDGETS{dirFrame}->Button(
   -activebackground    => 'white',
   -activeforeground    => '#1449ab',
   -background          => 'white',
   -borderwidth         => 2,
   -foreground          => $textblue,
   -height              => 0,
   -highlightbackground => '#efefef',
   -highlightcolor      => '#000000',
   -highlightthickness  => 0,
   -padx                => '1m',
   -pady                => '1m',
   -text                => 'Add folder',
   -width               => 8,
    -underline 	=>0,
   -command =>\&add_button_event,
  )->grid(
   -row    => 0,
   -column => 1,
   -sticky => 'ne',
  );

# Widget searchLabel isa Label
$ZWIDGETS{'searchLabel'} = $ZWIDGETS{inputFrame}->Label(
   -background => $bgblue,
   -takefocus  => 0,
   -text       => 'Search for this pattern:',
  )->grid(
   -row    => 1,
   -column => 0,
   -sticky => 'nw',
  );

# Widget findEntry isa Entry
$ZWIDGETS{'findEntry'} = $ZWIDGETS{inputFrame}->Entry(
   -background     => 'white',
   -foreground     => $textblue,
   -highlightcolor => 'black',
   -text =>$matchString,
   -width          => 155,
  )->grid(
   -row        => 2,
   -column     => 0,
   -columnspan => 4,
   -sticky     => 'ew',
  );

# Widget replaceLabel isa Label
$ZWIDGETS{'replaceLabel'} = $ZWIDGETS{inputFrame}->Label(
   -activebackground => '#efefef',
   -background       => $bgblue,
   -disabledforeground =>'#BEBEBE',					#DCE4F9',	#very light blue grey
   -text => 'Replace the pattern with this:',
  )->grid(
   -row    => 3,
   -column => 0,
   -sticky => 'nw',
  );

# Widget replaceEntry isa Entry
$ZWIDGETS{'replaceEntry'} = $ZWIDGETS{inputFrame}->Entry(
   -background          => 'white',
   -foreground          => $textblue,
   -highlightbackground => '#ffffff',
   -highlightcolor      => '#000000',
   -text	=>$replaceMatchWith,
   -width               => 155,
  )->grid(
   -row        => 4,
   -column     => 0,
   -columnspan => 4,
   -sticky     => 'ew',
  );

# Widget optionLabelframe isa Labelframe
$ZWIDGETS{'optionLabelframe'} = $WWIDGETS{'MW'}->Labelframe(
   -background => $bgblue,
   -text       => 'Options',
  )->grid(
   -row        => 1,
   -column     => 0,
   -columnspan => 3,
   -sticky     => 'new',
  );

# Widget fillLabel2 isa Label
$ZWIDGETS{'fillLabel2'} = $ZWIDGETS{optionLabelframe}->Label(
   -activebackground => '#efefef',
   -background       => $bgblue,
   -width            => 5,	#5
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'nw',
  );

# Widget optpanel1Frame isa Frame
$ZWIDGETS{'optpanel1Frame'} = $ZWIDGETS{optionLabelframe}->Frame(
   -background => $bgblue,
  )->grid(
   -row     => 0,
   -column  => 1,
   -rowspan => 5,
   -sticky  => 'nw',
  );

# Widget r_Checkbutton isa Checkbutton
$ZWIDGETS{'r_Checkbutton'} = $ZWIDGETS{optpanel1Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -text                => '-r  Recursively search sub-folders',
   -variable            => \$rs,
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'w',
  );

# Widget fs_Checkbutton isa Checkbutton
$ZWIDGETS{'fs_Checkbutton'} = $ZWIDGETS{optpanel1Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -command             => sub  {$safeMode=0 if $fs;}, #not safe anymore
   -highlightbackground => $bgblue,
   -indicatoron         => 1,
   -selectcolor         => '#b03060',
   -text                => '-fs Follow symbolic links',
   -variable            => \$fs,
  )->grid(
   -row    => 1,
   -column => 0,
   -sticky => 'w',
  );

# Widget v_Checkbutton isa Checkbutton
$ZWIDGETS{'v_Checkbutton'} = $ZWIDGETS{optpanel1Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -command => sub { $safeMode=0 if !$verbose; },
   -text                => '-v  Verbose results',
   -variable            => \$verbose,
  )->grid(
   -row    => 2,
   -column => 0,
   -sticky => 'w',
  );

# Widget dr_Checkbutton isa Checkbutton
$ZWIDGETS{'dr_Checkbutton'} = $ZWIDGETS{optpanel1Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -text                => '-dr Dry run mode',
   -variable            => \$dryRun,
  )->grid(
   -row    => 3,
   -column => 0,
   -sticky => 'w',
  );

# Widget bm_Checkbutton isa Checkbutton
$ZWIDGETS{'bm_Checkbutton'} = $ZWIDGETS{optpanel1Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -command => sub { $safeMode=0 if $safeMode; },
   -text                => '-b  Backup mode',
   -variable            => \$backupMode,
  )->grid(
   -row    => 4,
   -column => 0,
   -sticky => 'w',
  );

# Widget fillLabel3 isa Label
$ZWIDGETS{'fillLabel3'} = $ZWIDGETS{optionLabelframe}->Label(
   -background => $bgblue,
   -width      => 5,
  )->grid(
   -row    => 0,
   -column => 2,
   -sticky => 'nw',
  );

# Widget optpanel2Frame isa Frame
$ZWIDGETS{'optpanel2Frame'} = $ZWIDGETS{optionLabelframe}->Frame(
   -background => $bgblue,
  )->grid(
   -row     => 0,
   -column  => 3,
   -rowspan => 5,
   -sticky  => 'nw',
  );

# Widget confirmCheckbutton isa Checkbutton
$ZWIDGETS{'confirmCheckbutton'} = $ZWIDGETS{optpanel2Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -activeforeground    => '#000000',
   -background          => $bgblue,
   -command             => 
		sub { 
			if($confirm){	
				$noForce=0;	#ask for changes
				$force=0;		#don't say yes to all cases automaticly
   			}else{$safeMode=0;}
		},
   -foreground          => '#000000',
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -text                => '-c Confirm changes',
   -variable            => \$confirm,
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'w',
  );

# Widget transDCheckbutton isa Checkbutton
$ZWIDGETS{'transDCheckbutton'} = $ZWIDGETS{optpanel2Frame}->Checkbutton(
   -activebackground=> $bgblue,
   -activeforeground => '#000000',
   -background         => $bgblue,
   -command            =>sub {$transU=0 if $transD; },# can only do one or the other
   -foreground          => '#000000',
   -highlightbackground => $bgblue,
   -selectcolor         	=> '#b03060',
   -text                	=> '-td Translate all characters to lower case',
   -variable            	=> \$transD,
  )->grid(
   -row    => 1,
   -column => 0,
   -sticky => 'w',
  );

# Widget transUCheckbutton isa Checkbutton
$ZWIDGETS{'transUCheckbutton'} = $ZWIDGETS{optpanel2Frame}->Checkbutton(
   -activebackground => $bgblue,
   -activeforeground  => '#000000',
   -background          => $bgblue,
   -command             =>sub {$transD=0 if $transU;}, # can only do one or the other
   -foreground           => '#000000',
   -highlightbackground => $bgblue,
   -selectcolor           => '#b03060',
   -text                	=> '-tu Translate all characters to upper case',
   -variable            	=> \$transU,
  )->grid(
   -row    => 2,
   -column => 0,
   -sticky => 'w',
  );

# Widget yCheckbutton isa Checkbutton
$ZWIDGETS{'yCheckbutton'} = $ZWIDGETS{optpanel2Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -activeforeground    => '#000000',
   -background          => $bgblue,
   -command             => 
		sub {
  			if($force){
				$confirm=0;	#skip confirming changes and overwrites
				$noForce=0;	#don't say no to all changes
				$safeMode=0; #not safe anymore
  			}
		},
   -foreground          => '#000000',
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -text                => '-y Force all changes without confirming',
   -variable            => \$force,
  )->grid(
   -row    => 3,
   -column => 0,
   -sticky => 'w',
  );

# Widget nCheckbutton isa Checkbutton
$ZWIDGETS{'nCheckbutton'} = $ZWIDGETS{optpanel2Frame}->Checkbutton(
   -activebackground    => $bgblue,
   -activeforeground    => '#000000',
   -background          => $bgblue,
   -command             =>
	sub {
  		if($noForce){
			$confirm=0; #no need to confirm changes too 
			$force=0;   #turn off force if activated
			$safeMode=0; #not safe anymore
    		}
	},
   -foreground          => '#000000',
   -highlightbackground => $bgblue,
   -selectcolor         => '#b03060',
   -text                => '-n Don\'t force any changes and don\'t ask',
   -variable            => \$noForce,
  )->grid(
   -row    => 4,
   -column => 0,
   -sticky => 'w',
  );

# Widget fillLabel4 isa Label
$ZWIDGETS{'fillLabel4'} = $ZWIDGETS{optionLabelframe}->Label(
   -background => $bgblue,
   -width      => 5,
  )->grid(
   -row    => 0,
   -column => 4,
   -sticky => 'nw',
  );

# Widget fillLabel5 isa Label
$ZWIDGETS{'fillLabel5'} = $ZWIDGETS{optionLabelframe}->Label(
   -background       => $bgblue,
   -width      => 5,
  )->grid(
   -row    => 1,
   -column => 4,
   -sticky => 'nw',
  );

# Widget safeModeCheckbutton isa Checkbutton
$ZWIDGETS{'safeModeCheckbutton'} = $ZWIDGETS{optionLabelframe}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -command             =>
	sub {
		if($safeMode){ #auto config to the safest settings
  			#turn ON
 			$confirm=1;
			$verbose=1;
			$backupMode=1;
			#turn OFF
	 		$fs=0;	#following symbolic links is never safe
	 		$noForce=0;
	 		$force=0;
			event_turn_off_rx_settings();
	 		$noSanitize=0;
  		}
	},#end safeMode_button
   -highlightbackground => $bgblue,
   -text                => '-sm Safe mode',
   -variable            => \$safeMode,
  )->grid(
   -row    => 0,
   -column => 5,
   -sticky => 'w',
  );

# Widget filetypebutton isa Checkbutton
$ZWIDGETS{'filetypebutton'} = $ZWIDGETS{optionLabelframe}->Checkbutton(
   -activebackground    => $bgblue,
   -anchor              => 'center',
   -background          => $bgblue,
   -command             =>\&filetype_toggle_event,
   -highlightbackground => $bgblue,
   -text                => '-ft Filetype filtering',
   -variable            => \$filetypeMode,
  )->grid(
   -row    => 1,
   -column => 5,
   -sticky => 'nw',
  );

# Widget optpanel3Labelframe isa Labelframe
$ZWIDGETS{'optpanel3Labelframe'} = $ZWIDGETS{optionLabelframe}->Labelframe(
   -background => $bgblue,
   -text       => 'Advanced',
  )->grid(
   -row     => 3,
   -column  => 5,
   -rowspan => 2,
   -sticky  => 'nw',
  );

# Widget nosanCheckbutton isa Checkbutton
$ZWIDGETS{'nosanCheckbutton'} = $ZWIDGETS{optpanel3Labelframe}->Checkbutton(
   -activebackground    => $bgblue,
   -activeforeground    => '#000000',
   -background          => $bgblue,
   -command             =>sub {	event_turn_off_rx_settings();	$safeMode=0;},	 #not safe anymore 
   -foreground          => '#000000',
   -highlightbackground => $bgblue,
   -text                => '-ns Don\'t sanitize search / replace data',
   -variable            => \$noSanitize,
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'w',
  );

# Widget rxCheckbutton isa Checkbutton
$ZWIDGETS{'rxCheckbutton'} = $ZWIDGETS{optpanel3Labelframe}->Checkbutton(
   -activebackground    => $bgblue,
   -background          => $bgblue,
   -command             =>
	sub {
   		if($rx){
     			$safeMode=0;   #not safe anymore
     			$noSanitize=1; #don't want to scrub Regular expressions	
			$ZWIDGETS{'replaceLabel'}->configure( -state=>'disable'); 		#sleep until needed again....
			$ZWIDGETS{'replaceEntry'}->configure( -state=>'disable');		#sleep until needed again....
			$ZWIDGETS{'searchLabel'}->configure( -text=>"Regular expression:");
# 			if($filetype){	#dont want this fucking up Regex data
# 				$filetype=0;
#  				filetype_toggle_event();
# 			}
  		}
		else{ event_turn_off_rx_settings(); }
	},
   -highlightbackground => $bgblue,
   -text                => '-x   Regular expression mode',
   -variable            => \$rx,
  )->grid(
   -row    => 1,
   -column => 0,
   -sticky => 'w',
  );



#######  updated main window frame with this
$ZWIDGETS{'filetypeFrame'} = $WWIDGETS{'MW'}->Frame(
   -background => $bgblue,
  )->grid(
   -row    => 1,
   -column => 3,
   -sticky => 'ne',
  );

# Widget fillLabel1 isa Label
$ZWIDGETS{'fillLabel1'} = $ZWIDGETS{'filetypeFrame'}->Label(
   -background => $bgblue,
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'ne',
  );

# Widget filetypeLabel isa Label
$ZWIDGETS{'filetypeLabel'} = $ZWIDGETS{'filetypeFrame'}->Label(
   -anchor             => 'w',
   -background         => $bgblue,
   -disabledforeground => $bgblue,
#    -justify            => 'right',#left
   -padx               => 1,
   -pady               => 1,
   -relief             => 'flat',
   -state              => 'disable',
   -text               => 'Filetype:',
   -width              => 10,
  )->grid(
   -row    => 1,
   -column => 0,
   -sticky => 'nw',
  );

# Widget filetypeEntry isa Entry
$ZWIDGETS{'filetypeEntry'} = $ZWIDGETS{'filetypeFrame'}->Entry(
   -background          => '#fdf2f5f3e6d6',
   -foreground          => $textblue,
   -disabledforeground => $bgblue,
   -disabledbackground => $bgblue,
   -borderwidth =>1,
   -highlightbackground => $bgblue, #default on is white, hide mode #6fa9e4
   -highlightcolor=>$bgblue,	#default on is black, hide mode #6fa9e4
   -relief=>'flat',				#default on is sunken, hide mode flat
   -state              => 'disable',
   -takefocus          => 1,
   -width              => 10,
   -text=>$filetype,
  )->grid(
   -row    => 2,
   -column => 0,
   -sticky => 'nw',
  );
######

# Widget runButton isa Button
$ZWIDGETS{'runButton'} = $WWIDGETS{'MW'}->Button(
   -command =>\&run_and_stop_button_event,
   -activebackground    => 'white',
   -activeforeground    => '#1449ab',
   -background          => 'white',
   -foreground          => $textblue,
   -highlightbackground => $bgblue,
   -highlightcolor      => '#000000',
   -padx                => '1m',
   -underline =>0,
   -textvariable            => \$runstopMessage,
   -width               => 5,
   -wraplength          => 0,
  )->grid(
   -row    => 2,	
   -column => 3,
   -sticky => 'se',
  );

# Widget outputROText isa ROText
$ZWIDGETS{'outputROText'} = $WWIDGETS{'MW'}->Scrolled('ROText',
   -scrollbars          => 'oe',	#'ow'
   -background          => 'white',
   -borderwidth         => 2,
   -foreground          => $textblue,
   -highlightbackground => $bgblue,
   -insertwidth         => 2,
   -padx                => 2,
   -pady                => 1,
   -relief              => 'sunken',
  )->grid(
   -row        => 3,
   -column     => 0,
   -rowspan    => 2,
   -columnspan => 4,
   -sticky => "nsew",
  );
  $ZWIDGETS{'outputROText'}->Subwidget("yscrollbar")->configure(
			-background => "#DCE4F9", 
			-jump =>1,
			-command => ['yview' => $ZWIDGETS{'outputROText'}]
	); 			#color the position bar very light blue
  	$ZWIDGETS{'outputROText'}->yviewScroll(18, "page");	#page by space-bar press 

# Widget messageLabel isa Label
$ZWIDGETS{'messageLabel'} = $WWIDGETS{'MW'}->Label(
   -activeforeground => '#000000',
   -background       => $bgblue,
   -foreground       => $textblue,
   -highlightcolor   => '#000000',
   -justify          => 'left',
   -relief           => 'flat',
   -textvariable     => \$message,
  )->grid(
   -row        => 5, #2
   -column     => 0,
   -columnspan => 4,
   -sticky     => 'sw',
  );

# Widget confirmLabelframe isa Labelframe
$ZWIDGETS{'confirmLabelframe'} = $WWIDGETS{'MW'}->Labelframe(
   -background => $bgblue,
   -foreground =>'grey',
   -text       => 'Confirm',
  )->grid(
   -row    => 5,
   -column => 3,#3
   -sticky => 'se',#se
  );

# Widget confirmYButton isa Button
$ZWIDGETS{'confirmYButton'} = $ZWIDGETS{confirmLabelframe}->Button(
   -activebackground    => 'white',
   -activeforeground    => '#1ec68dd22be0',
   -background          => 'white',
   -command             => sub { $isOK = 1 },
   -foreground          => 'Black',
   -highlightbackground => $bgblue,
   -highlightcolor      => '#000000',
   -padx                => '1m',
   -pady                => '0m',
   -state               => 'disabled', #normal',
   -takefocus           => 1,
   -text                => 'Yes',
   -underline  =>0,
   -width               => 5,
  )->grid(
   -row    => 0,
   -column => 0,
   -sticky => 'ne',
  );

# Widget confirmNButton isa Button
$ZWIDGETS{'confirmNButton'} = $ZWIDGETS{confirmLabelframe}->Button(
   -activebackground    => 'white',
   -activeforeground    => 'red',
   -background          => 'white',
   -command             => sub { $isOK = 0 },
   -highlightbackground => $bgblue,
   -padx                => '1m',
   -pady                => '0m',
   -state               => 'disabled',  #normal',
   -text                => 'No',
   -underline 	=>0,
   -width               => 5,
  )->grid(
   -row    => 0,
   -column => 1,
  );

###############################
#bind key-commands to the mainWindow events
###############################
  $WWIDGETS{'MW'}->bind('<Control-Key-c>' =>sub {_clearOutput();});			#clear the ROText box
  $WWIDGETS{'MW'}->bind('<Control-Key-o>' =>sub {_clearOptions();});		#reset Options
  $WWIDGETS{'MW'}->bind('<Control-Key-n>' =>sub { resetNew();} );			#reset the program
  $WWIDGETS{'MW'}->bind('<Control-Key-q>' =>sub {_closeCleanly();});			#exit the program
  $WWIDGETS{'MW'}->bind('<Alt-a>' =>sub {add_button_event();});				#mimick activating the add folder button
  $WWIDGETS{'MW'}->bind('<Alt-r>' =>sub {run_and_stop_button_event();}); 		#mimick activating the run button
  $WWIDGETS{'MW'}->bind('<Alt-s>' =>sub {run_and_stop_button_event();}); 		#mimick activating the stop button (aka the run button)
  $WWIDGETS{'MW'}->bind('<Alt-y>' =>sub {$isOK=1}); 							#mimick confirmYButton press
  $WWIDGETS{'MW'}->bind('<Alt-n>' =>sub {$isOK=0});							#mimick confirmNButton press

###############
#
# MainLoop
#
###############

MainLoop;												#start the main GUI

#######################
#
# Subroutines
#
#######################
#
#### GUI events  ##
#

sub halt_isok_event(){
	$isOK=-1; 	#tell any proccess waiting for this variable to change to have a cancel result
}#end halt_isok_event

sub _closeCleanly(){#close the program safely
	halt_isok_event(); 	#tell any proccess waiting for this variable to change to have a cancel result
	exit;			#nothing to save, so just quit
}#end _closeCleanly()

sub resetNew(){
 	halt_isok_event();		#Halt the existing batch job, since changing the following settings would affect its operation.
	$batchJobCount=1; #reset the count batchjob clock
	_clearInput(); 
	_clearOptions(); 
	_clearOutput();
}#end resetNews

sub _clearInput{ #clearing the input boxes
   my $saveFTmode=$filetypeMode;
	#order is important for this to cover all cases, including possible disabled state Entry boxes
	event_turn_off_rx_settings();
	if($filetypeMode<=0 ){
		$filetypeMode=1;
		filetype_toggle_event();
	}
	#scrub the input Entry boxes
 	$ZWIDGETS{'folderEntry'}->delete('0','end');
  	$ZWIDGETS{'findEntry'}->delete('0','end');
  	$ZWIDGETS{'replaceEntry'}->delete('0','end');
  	$ZWIDGETS{'filetypeEntry'}->delete('0','end');
	#hide the filetype frame if it was hidden before this method call
	if($saveFTmode<=0){
		$filetypeMode=0;
		filetype_toggle_event();
	}

} #end _clearInput

sub _clearOptions(){#turn all options off
#reset the values to 0
   event_turn_off_rx_settings();		#note: $rx is set to 0 in this called method
   ($confirm, $force, $noForce, $dryRun, $transD, $transU, 
	$noSanitize, $rs, $verbose, $backupMode, $fs, 
	$safeMode, $filetypeMode, $batchJobCount
   )=0;		
   filetype_toggle_event();
}#end _clearOptions

sub _clearOutput() { #clear the ROText box
 	$ZWIDGETS{'outputROText'}->delete("1.0",'end'); 
};#end _clearOutput()

sub run_and_stop_button_event(){
   		if($runstopMessage =~m/run/i){
			#grab needed input
		   	$startDir=$ZWIDGETS{'folderEntry'}->get();
			$matchString=$ZWIDGETS{'findEntry'}->get();
			$replaceMatchWith=$ZWIDGETS{'replaceEntry'}->get();
			if ((($matchString eq "") and ($replaceMatchWith eq "")) and ($transU ==0 and $transD==0)){
				return;
			}
			$runstopMessage="Stop";	#change the button name
   			$ZWIDGETS{'runButton'}->configure(-foreground=>'Red',  -activeforeground=>'Red');
			main();	#run the core code
		}else{#capture stop mode and close a runnning process
			$message="Please wait a moment while I stop the batch job....";
			$ZWIDGETS{'runButton'}->configure(
							-foreground=>'Black',		#show visually a yellow text color that Stopping is in progress
							-background=>'#dd42ef196fa8',
						);	
			#no need to wait until the stack uncoils, resets isOK back to 0, and returns cleanly
			halt_isok_event();	#reset and trigger the confirmChange sleep to awaken and uncoil the Run stack safely 
			return;
		}
}#ned run_and_stop_button_event

sub event_turn_off_rx_settings{	#toggle rx settings to off configuration
	#reset the labels and enable the entry box
	$ZWIDGETS{'searchLabel'}->configure( -text=>"Search for this pattern:");
	$ZWIDGETS{'replaceLabel'}->configure( -state=>'normal'); 		#awaken if asleep
	$ZWIDGETS{'replaceEntry'}->configure( -state=>'normal'); 		#awaken if asleep
	$rx=0;
}#end event_turn_off_rx_settings()

sub filetype_toggle_event(){#	Toggle_filetype on and off events
#purpose is to either show or hide the label and entry widgets that deal with the filetype filter
#The state of either being show or hidden is managed by the state of the filetype checkbox
	if($filetypeMode){
		$ZWIDGETS{'filetypeLabel'}->configure(-state=>'normal');
		$ZWIDGETS{'filetypeEntry'}->configure(-state=>'normal',
				-highlightbackground => 'white', 			#default on is white colour
				-highlightcolor=>'black',					#default on is black
				-relief=>'sunken',						#default on is sunken
				-takefocus => 1,						#have tabable focus
			);
#  		event_turn_off_rx_settings() if $rx;
	}else{	#hide the filetype label and entry widgets
			#disable and hide configure(-state=>'disable');
		$ZWIDGETS{'filetypeLabel'}->configure(-state=>'disable');
		$ZWIDGETS{'filetypeEntry'}->configure(-state=>'disable',
				-highlightbackground => $bgblue, 		# hide mode blue background colour used everywhere else
				-highlightcolor=>$bgblue,				# hide mode blue background colour used everywhere else
				-relief=>'flat',							#hide mode flat to blend into the surroundings
				-takefocus => 0,						#hide from tab focus
			);
	}
}#end filetype_toggle_event

sub add_button_event(){#create a dialog for choosing a folder to traverse
 my $curr_dir = "";
       	if (-d $ZWIDGETS{'folderEntry'}->get()){ $curr_dir=$ZWIDGETS{'folderEntry'}->get(); }
	else{ $curr_dir = Cwd::cwd(); }

my $title="Choose a directory!";
	if (SLASH eq "\\"){#normal dialog box for Windows folk
		$curr_dir=$WWIDGETS{'MW'}->chooseDirectory( -initialdir =>$curr_dir , -title => $title);
	}
	else{#A better dialog box for Unix folk =)
 		my $getdir=AddDirTk->new("\#6fa9e4", "\#08528b"); 
		$curr_dir=$getdir->buildGUI($title, $curr_dir);
		$getdir->DESTROY();
	}

	if (defined $curr_dir and ($curr_dir ne "")){
 		$ZWIDGETS{'folderEntry'}->delete('0','end');
 		$ZWIDGETS{'folderEntry'}->insert('end',$curr_dir);
	}

}#end add_button_event

sub _build_about_box($){#build the about reading box of manuals and guides. Param is scalar Title for the window frame
  my ($title)=@_;

 $WWIDGETS{'ABOUT'}= new MainWindow(-title=>$title);
 $WWIDGETS{'ABOUT'}->bind(<'Alt-z'>=> sub{$WWIDGETS{'ABOUT'}->Destroy();});

# Widget create  menu bar with a help option 
 my $mbar = $WWIDGETS{'ABOUT'}->Menu(  -background =>$bgblue,  -relief => 'flat', -borderwidth =>0 );
 $WWIDGETS{'ABOUT'}-> configure(-menu => $mbar,  -background =>$bgblue );
 my $mbarHelp = $mbar-> cascade( -label =>"Help", -underline=>0, -tearoff => 0 );	#help menu drop down list
 $mbarHelp->command(
   	-background=>'white',
   	-activebackground=>$bglightblue,
   	-label =>"Manual",				#About option shows the manual
   	-underline => 2,
   	-command =>sub #use existing window and replace the text and title bar
		{
			$WWIDGETS{'ABOUT'}->configure(-title=>"$progn\'s Manual");
			$ZWIDGETS{'aboutTxt'}->delete('1.0','end');
			_getManual();
		},
  );
 $mbarHelp->command(
   	-background=>'white',
   	-activebackground=>$bglightblue,
	-label =>"Advanced Tutoral",
	-underline=>1, 
	-command => sub #use existing window and replace the text and title bar 
		{
			$WWIDGETS{'ABOUT'}->configure(-title=>"$progn\'s A regular expression walk-through");
			$ZWIDGETS{'aboutTxt'}->delete('1.0','end');
			_getRegex();
		},
  );#option Regex lession

 #$mbarHelp-> separator(-background =>'white', -foreground=>'black');	#look up color tweaking since these options are doing anything

 $mbarHelp->command(
   	-background=>'white',
   	-activebackground=>$bglightblue,
	-label =>"Terms of use", 
	-underline=>1, 
	-command =>sub #use existing window and replace the text and title bar
 		{
			$WWIDGETS{'ABOUT'}->configure(-title=>"$progn\'s End User License Agreement");
			$ZWIDGETS{'aboutTxt'}->delete('1.0','end');
			_getLicense();
		},
  ); #end user license agreement  option

#Making a text area
  $ZWIDGETS{'aboutTxt'} = $WWIDGETS{'ABOUT'}->Scrolled(
	'ROText',
	-background =>'white',#6fa9e4',	#light blue
	-borderwidth=>4,
	-foreground=>$textblue,
	-highlightbackground=>'White',
	-relief=>'flat',
	-width => 125,					#note: the text box size defines the default window size
	-scrollbars=>'oe',					#vertical west scrollbar .... not "e"
	-highlightcolor=>'#fdf2f5f3e6d6',		#special white color
	-highlightthickness=>2,
	-selectbackground =>'#035093',		#blue color of the background when selecting text
	-selectborderwidth=>1,
	-selectforeground=>'#E27530',		#orange color of text when selected
   );
  #NOTE-- tweak the scrollbar colors futher-- see chapter 6,3
  $ZWIDGETS{'aboutTxt'}->Subwidget("yscrollbar")->configure(-background => "#DCE4F9");  #make the scroll bar light blue color

 #The packing commands
  $ZWIDGETS{'aboutTxt'} -> pack(-expand => 1, -fill => "both", -side => "left"); #make the widgets be resizable
  $WWIDGETS{'ABOUT'}->bind('<Control-Key-w>', sub 
	{
		$WWIDGETS{'ABOUT'}->destroy(); 
		$WWIDGETS{'ABOUT'}="";
	}
  );

}#end _build_about_box($)

sub _getManual(){
	$ZWIDGETS{'aboutTxt'}->insert('end', manual());
# 	$ZWIDGETS{'aboutTxt'}->insert('end', $files->getFile('manual')); 
}#end _getManual

sub _getRegex(){
  #Inject manual into readonly text box 
   if ($files->getFile('tutoral') eq ""){ $ZWIDGETS{'aboutTxt'}->insert('end', regrex())  }
   else{						    $ZWIDGETS{'aboutTxt'}->insert('end', $files->getFile('tutoral'));  }
}#end _getRegex

sub _getLicense(){
 	$ZWIDGETS{'aboutTxt'}->insert('end', copyright());
	$ZWIDGETS{'aboutTxt'}->insert('end', $files->getFile('gpl'));
# 	read_file(Cwd::cwd() .  SLASH . "GPLv2.txt");
}#end _getLicense


sub _aboutHelpMenu_button($){
 my ($opt)=@_;
  _build_about_box("$progn\'s $opt");

   $ZWIDGETS{'aboutTxt'}->delete('1.0','end');
   if($opt eq "Manual"){  _getManual(); } 
   elsif($opt eq "EULA"){ _getLicense(); } 
   elsif($opt eq "Regex"){  _getRegex(); }
}#end _aboutHelpMenu_button



##############
##core subroutines
#############

sub msg($){ 	#append message into the ReadOnlyText box	
	$ZWIDGETS{'outputROText'}->insert('end', (shift) . "\n");	#right way to jump to the next line
 	$ZWIDGETS{'outputROText'}->see('end');	#update the viewable part of the text to scroll downward to the last position in the y scroll plane
}#end msg

sub activateSafeMode(){#auto config settings if this mode is activated
	if ($safeMode){	
		$confirm=1;
		$verbose=1;
		$backupMode=1;
		$force=0;
		$noForce=0;
		$fs=0;
		$noSanitize=0 if $rx==0;
	}
 }#end activateSafeMode

sub confirmChange($$){ 	#ask if pending change is good or bad. Parameters $currentFilename and $newFilename
  my ($currentf, $newf)=@_;  my $answer="";
  msg(" Confirm change: " . getPerms($currentf) . " " .Cwd::getcwd() .SLASH."\"$currentf\" to \"$newf\"");
  msg("\t\t YES or NO");

#activate the confirmframe buttons
  #$isOK=0; #ensure that it's reest before use as a flag
  $message="Take your time while I wait for your answer  -->>";
  $ZWIDGETS{'confirmLabelframe'}->configure( -foreground =>'Black');
  $ZWIDGETS{'confirmYButton'}->configure( -state=>'normal');
  $ZWIDGETS{'confirmNButton'}->configure( -state=>'normal');

#sleep until the variable changes value =-1,0,1)	where 1=yes 0=no, -1=flag for uncoil and stop the Run button  stack
  $ZWIDGETS{'confirmLabelframe'}->waitVariable(\$isOK);		
#print "confirm answer capture is $isOK\n";
###de-activate the confirmframe buttons####
  $message="Thanks....";
  $ZWIDGETS{'confirmYButton'}->configure( -state=>'disable');		#sleep until needed again....
  $ZWIDGETS{'confirmNButton'}->configure( -state=>'disable');	#tough, you will nap because I say so
  $ZWIDGETS{'confirmLabelframe'}->configure( -foreground =>'grey');
  $message="";
 return $isOK;	
}#end confirmChage($)

sub getPerms($){ 	#OS detect, then get file permisions in *nix or windows format. Parameter=$file to lookup
 	return FilePerms::getUnixPerms(shift) if (SLASH eq "/");
	return FilePerms::getWinPerms(shift)  if (SLASH eq "\\");
 	return "???";
}#end getPerms($)

sub fRename($){ #file renaming... only call this when not crawling any subfolders. Parameter = $folder to look at
 my ($dir)=@_;
  return 1 if (! -d $dir); #skip this if not a valid directory name
  chdir ($dir);		#must change folder reading location so other file data is accessable on a file per file basis, such as FilePerms methods
  my @dfiles=$files->getFolderList($dir);#Readfiles::getFolderList($dir
#   print join (",", @dfiles),  "\n";
   if (scalar @dfiles > 2){#not empty and not containing just  "." & ".."
	foreach my $fname (@dfiles) { _rFRename($fname); } # one at a time, process each file/folder name
   }else{ msg( "ATTENTION: Either this folder is empty or cannot be opened for reading: $dir"); }
}#end frename($)

sub _translateUD($){	#translate case either up or down. Parameter = $file
  ($_)=@_;
	return uc if($transU);
	return lc if($transD);
  return $_;
}#end _translateUD($)

sub _rFRename($){ 	#recursive file renaming processing. Parameter = $file
  my ($fname)=@_;
    return if($fname=~m/^(\.|\.\.)$/ ); #if not writable, then move along to another file (!-w $fname) 
    return if $isOK==-1;	#stop button hit, uncoil the Run button stop

    #check the filetypeMode and if active, then filter out any files that don't fit the filetype 
    if($filetypeMode){
	$filetype=~s/\s//g; 					#trim whitespaces
	return if (not $fname=~m/$filetype$/i);	#case insensative search
    }

    if($rx || $fname=~m/$matchString/ || ($transU || $transD)){
	 my $fold=$fname;
	 if (! $rx){
		if(($matchString eq "" && ($transU || $transD)) or $fname=~m/$matchString/){
			if( not  ($matchString eq "" && ($transU || $transD))) {
				eval $fname=~s/$matchString/$replaceMatchWith/g; 
				if ($@){ msg( " Warning -> Regex problem against $fname:$@");}
			}
			$fname = _translateUD($fname);
		}
	 }else{	#using regex for translation: example where f='s/^(foo)gle/$1bar/'  or f='tr/a-z/A-Z/'  or f='s/(foo|foobar)/bar/g'
		$_=$fname if !$rs;
    		eval $matchString;
    		if ($@){ msg( " Warning -> Regex problem against file name $fname: $@");}
		else {   $fname = _translateUD($_) if ($fname ne $_); }	#if the name was changed, next try translation
	 }

	 return if ($fold eq $fname); #nothing has changed-- ignore quietly

	my  $confirmAnswer;
	 if(!$force  && ($confirm || -e $fname)) {### does a file exist with that same "new" filename? should it be overwritten?
		### mod to also show file size and age of current existing file
		if(-e $fname and !$noForce){	 
			 msg(">Transformation: the following file already exists-- overwrite the file? $fname");
			 msg("--->"); #not added to the above line with a so that propper OS detection next line is managed
		}
		return if $noForce;	#dont want to force changes?
		 $confirmAnswer=confirmChange($fold,$fname);	#1= yes change it, 0= no don't, -1=kill run flag
		if($confirmAnswer==0){ msg( " -->Skipped: $fold") if $verbose;  return; }
		elsif ($confirmAnswer < 0){#Flag for-- Kill exicution stack for Run, since Stop was pressed
			msg("::.::State Change:  Stopping...::.::");
			return;
		}

	 }
	

	 if($backupMode){
# 		my $bak;
# 		if (SLASH eq "/"){ $bak=$fold . "~";}	#for unix and less clutter 
# 		else{$bak=$fold . ".bak";}			#for MS Windows
# 
# 		if(-e $bak and !$noForce){	 
# 			 msg(">Transformation: the following backup file already exists-- overwrite the file? $bak");
# 			 msg("--->"); #not added to the above line so that propper OS detection next line is managed
# 		}
# 		return if $noForce;	#dont want to force changes?
# 		$confirmAnswer=confirmChange($fold,$bak);	#1= yes change it, 0= no don't, -1=kill run flag
# 		if($confirmAnswer==0){ msg( " -->Skipped: $fold") if $verbose;  return; }
# 		elsif ($confirmAnswer < 0){#Flag for-- Kill exicution stack for Run, since Stop was pressed
# 			msg("::.::State Change:  Stopping...::.::");
# 			return;
# 		}
# 		
# 		
# 		eval {copy($fold, $bak);}		
	 }

	 eval { rename ($fold, $fname); };	#try to rename the old file to the new name
  	 if ($@) {
		msg( "ERROR-- Can't rename " . Cwd::getcwd() . SLASH . "\"$fold\" to \"$fname\": $!");
  	 }else {
		msg(" Updated " . getPerms($fname) . " " . Cwd::getcwd() . SLASH . "\"$fold\" to \"$fname\"")   if ($verbose); 
		++$fcount; # if ($verbose && !$force);
	 }
    }
}#end _rFRename($;$)

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
	return if $noSanitize || $rx;		#don't treat regular expressions or when asked to turn sanitize mode off
	$matchString=_untaintData($matchString,1);
	$replaceMatchWith=_untaintData($replaceMatchWith,0);
	return;
}#end untaintData

sub bool ($){	return (shift >=1) ? "On" : "Off";  } #translate values to boolean On or Off string

sub main(){
#    cmdlnParm() 	if ($version || $help || ($matchString eq "" and (!$transU && !$transD)) );

#get the data from the user
  $startDir=$ZWIDGETS{'folderEntry'}->get();
  $matchString=$ZWIDGETS{'findEntry'}->get();
  $replaceMatchWith=$ZWIDGETS{'replaceEntry'}->get();
   
  $filetype=$ZWIDGETS{'filetypeEntry'}->get() if ($filetypeMode);

  $noSanitize=1 	if ($rx and $noSanitize==0);	#don't treat regular expressions
  activateSafeMode();		#should it auto config to the safest settings?




  if ($batchJobCount ne 1){ #when batch job X != 1st time
	msg(""); msg("---------- ------------ ----------- ----") 	
  }
  msg("$progn is using Perl version $]")	if (($batchJobCount eq 1) and ($verbose)) ;
  if ($verbose) {
		msg("Batch Job: $batchJobCount - ". scalar localtime( time() ));
  }else { msg("Batch Job $batchJobCount:");}

  
  $fcount=0;  		#reset file count if it has not already happened
  
   if($verbose){ #show settings that will be used?	
	
	 msg( "   Use this data  { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }") if !$rx;
	 untaintData();
	 msg( "   Data sanitized { search for: '$matchString'\t\t-->replace with: '$replaceMatchWith' }") if !$noSanitize;
	 msg( "   Start directory: $startDir" );
 	 msg( "   Recursive mode: ".bool($rs) );
	 msg( "   Follow symbolic links: ".bool($fs) );
	 msg( "   Confirm changes: ". bool($confirm) );
	 msg( "   Force changes: ".bool($force) );
	 msg( "   Don't overwrite files: " .bool($noForce) );
	 msg( "   Regular expression mode: ".bool($rx) );
	 msg( "   Case-Translate Upper-to-Lower: ".bool($transD) );
	 msg( "   Case-Translate Lower-to-Upper: ".bool($transU) );
	 msg( "   Verbose option: ".bool($verbose) );
	 msg( "   Dry run mode: ".bool($dryRun) );
	 msg( "   Backup mode: ". bool($backupMode) );
 	msg( "   Safe mode autoconfig: " . bool($safeMode) );
	msg( "" );
   }else {untaintData();}
# return ;	#exit without killing the program.... 

   if ($rs){ #recursively traverse the filesystem?
	if ($fs) { File::Find::find( {wanted=> sub {_rFRename($_);}, follow=>1} , $startDir ); } #follow symbolic links?
	else{ finddepth(sub {_rFRename($_); }, $startDir); } 	#follow folders within folders
   }else{ fRename($startDir); }  						#only look at the given base folder

   if ($verbose){
   	msg( "----------------------------------------");
   	msg("Total files changed $fcount"); 
   }

   $isOK=0;				#reset flag
   $runstopMessage="Run";  	#reset name
   $ZWIDGETS{'runButton'}->configure(-foreground=>$textblue, -activeforeground    => '#1449ab'); #reset colors
#    -activebackground    => 'white',
#    
#    -background          => 'white',
#    -foreground          => '#08528b',
#    -highlightbackground => '#6fa9e4',
#    -highlightcolor      => '#000000',


		#add release disabled checkbutton options to normal
   $batchJobCount++;
}#end main()

sub manual(){
my $n=qw($1);	#use $n to overt throwing a contactation error
 return <<EOD;
   Usage: $progn optionalOptions -f=match -s=replaceWith -d=/var/music

	-f=foo            Default ""   Find--match this string 
	-s=bar            Default ""   Substitute--replace the matched string with this.
	-d=/var/music     Default "./" Directory to begin searching within.

   optional:
	-r		Recursively search the directory tree.
	-fs		Follow symbolic links when recursive mode is on.
	-v		Verbose-- show settings and all files that will be changed.
	-c		Confirm each file change before doing so.
	-[tu|td]	Case translation-- translate up or translate down.
	-y		Force any changes without prompting-- including overwriting a file.
	-n		Do not overwrite any files, and do not ask.
	-x		User defined regular expression mode. See examples for more details.
	-ns		Do not sanitize find and replace data. Note: this is turned off when -x mode is active.
	-sm		Safe mode auto configures $progn to run with only the safest settings turned on.
	-b		Backup files before renaming them. Ex: foobar.txt --> foobar.txt.bak
	-dr		Dry run mode: See what will change and if they're any conflicts without risk.
	-help		Usage options.
	-version	Version of $progn.

Description: $progn -- A bulk file renaming program.

   Examples:
	Search the entire music folder and replace and spaces after a track number to a dot, and, also,
	confirm changes. So this "01  song name.ogg" translates to "01.song name.ogg"
		$progn -c -x -r -d=/var/music/ -f='s/^(\\d\\d)\\s+/$n\./'

	In the current folder, remove all blank spaces in filenames and replace them with underscores.
		$progn -f=" "	-s="_"		OR	frenamer -x -f='s/\\s/_/g'

	Make sure all my image filenames are in lowercase.
		$progn -r -d=./images/ -td
	Or, only change the case for files with the word "NASA" in them to all upcase characters. 
	Note: if the substute option is omitted, then "NASA" will be removed from the matched 
	filename before the case is changed.
		$progn -r -tu -d=./images/ -f="NASA" -s="NASA"
EOD
}#end manual()

sub regrex(){
return <<EOD;
Go see the regrex.txt file
EOD
}#end regrex

sub copyright(){
return <<EOD;
$progn was authoured by Jason Campisi 
This is version $v copy(left and right) 2008.

This software offers no warranty and its creator admits no wrong doing
if damage occurs while in use, so beware and use at your own risk.
Be using this software you admit to these terms of no liability.

Also, this software is released under the terms of the GPL v2 or higher.
{ http://www.fsf.org/licensing/licenses/info/GPLv2.html }
------------------------------------------------------------------------------------------
EOD
}#end copyright()

#main();		#run the code

__END__
