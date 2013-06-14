#!/usr/bin/perl -w
#!perl
############
##Author Jason Campisi
##File: Readfile.pm v0.1
##Date: 2.15.2008
##EULA: GPLv2 or higher { http://www.fsf.org/licensing/licenses/info/GPLv2.html }
package AddDirTk;
use strict;
use Tk 804;
use Tk::FileSelect;
use Tk::DirTree;
use Fcntl  ':flock'; # import LOCK_* constants;
use warnings;
use Data::Dumper;

sub new(;$$){
my ($self, $bgcolor, $textcolor)=@_;

   $self={};
   bless ($self);
    if ($bgcolor ne ""){
 	$self->{'bgcolor'}=$bgcolor;
   } else{
 	$self->{'bgcolor'}="\#efefef";
   }
    if ($textcolor ne ""){
  	$self->{'textcolor'}=$textcolor;
    } else{
 	$self->{'textcolor'}="\#08528b";
    }
 	$self->{'startDir'}=".";
	$self->{'title'}="Choose a directory";
	$self->{'showhidden'}=0;
#    print Dumper $self;
  return $self;
}#end new

sub DESTROY(){
    my ($self)=@_;
	$self->{'t_ADD'}->destroy() if defined $self->{'t_ADD'};
	$self->{'ADD'}->destroy() if defined $self->{'ADD'};
     foreach my $item (keys %{$self}){ delete $self->{$item}; }
}#end Destroy

sub buildGUI(;$$){	#Param: "title" "start_directory"   Create a dialog for choosing a folder to traverse
###NOTE: needs tweaking for showing hidden files
my ($self, $title, $startDir)=@_;		#Choose a directory
  $self->{'ADD'} = new MainWindow(); 	
    $self->{'ADD'}->withdraw;
    $title=$self->{'title'} if $title eq "";
    $self->{'t_ADD'} =  $self->{'ADD'}->Toplevel (title=>$title,);

  my $showorhide=0; 

  my $ok = 0; 		# flag: "1" means OK, "-1" means cancelled
  $self->{'t_ADD'}->protocol( 'WM_DELETE_WINDOW' =>sub {$ok=-1;}); #capture the close window x-button press & exit safely



# Create Frame widget before the DirTree widget, so it's always visible
# if the window gets resized.
  $self->{'f_ADD'} = $self->{'t_ADD'}->Frame(-background =>$self->{'bgcolor'})->pack(-fill => "x", -side => "bottom");

  my $curr_dir = Cwd::cwd();   #Needs tweaking for windows support    http://perldoc.perl.org/Cwd.html 
# $curr_dir=$startDir if ((defined $startDir) and ($startDir -d));
#       $curr_dir=$self->{'folderEntry'}->get()	if (-e $self->{'folderEntry'}->get());	#use the existing folder in the folderEntry box if it's valid


 $self->{'d_ADD'} = $self->{'t_ADD'}->Scrolled('DirTree',
	-scrollbars => 'osoe',
	-width => 50,
	-height => 30,
  	-background =>'White',
        -highlightcolor      => 'white',
	-showhidden =>$showorhide,
	-selectmode => 'browse',
	-exportselection => 1,
	-browsecmd => sub { $curr_dir = shift },	#$curr_dir = shift
	# With this version of -command a double-click will
	# select the directory
	-command   => sub { $ok = 1 },
	# With this version of -command a double-click will
	# open a directory. Selection is only possible with
	# the Ok button.
 )->pack(-fill => "both", -expand => 1);

 $self->{'d_ADD'}->chdir($curr_dir);	# Set the initial directory

 $self->{'f_ADD'}->Button(-text => 'Ok',
   -command => sub { $ok =  1; },
   -activebackground    => 'white',
   -activeforeground    => '#1449ab',
   -background          => 'white',
   -borderwidth         => 2,
   -foreground          => $self->{'textcolor'},
   -height              => 0,
   -highlightbackground => '#efefef',
   -highlightcolor      => '#000000',
   -highlightthickness  => 0,
     -underline =>0,	#underline the 'O' in Ok
 )->pack(-side => 'left');


 $self->{'f_ADD'}->Button(-text => 'Cancel',
   -command => sub { $ok = -1; },
   -activebackground    => 'white',
   -activeforeground    => '#1449ab',
   -background          => 'white',
   -borderwidth         => 2,
   -foreground          => $self->{'textcolor'},
   -height              => 0,
   -highlightbackground => '#efefef',
   -highlightcolor      => '#000000',
   -highlightthickness  => 0,
     -underline =>0, #underline the C in cancel
 )->pack(-side => 'left');


my $shMessage="Show all files";
my $cb=$self->{'f_ADD'}->Checkbutton(
    -activebackground => $self->{'bgcolor'},
    -activeforeground  => '#000000',
    -background          => $self->{'bgcolor'},
    -foreground           => '#000000',
    -highlightbackground => $self->{'bgcolor'},
    -selectcolor           => '#b03060',
    -textvariable            => \$shMessage,
    -variable            	=> \$showorhide,
    -command =>sub 
	{
		 if ($showorhide){
#  			$shMessage="Show hidden files";
			$self->{'d_ADD'} ->configure(-showhidden =>1, );
# 			$self->{'d_ADD'} ->DoOneEvent;
 			
		}else{
# 			$shMessage="Show all files";
			$self->{'d_ADD'} ->configure(-showhidden =>0, );
# 			$self->{'d_ADD'} ->DoOneEvent;
		}
	},
   )->pack(-side => 'right');


  $self->{'t_ADD'}->bind('<Alt-o>' =>sub {$ok=1}); 						#mimick confirm Ok Button press
  $self->{'t_ADD'}->bind('<Alt-c>' =>sub {$ok=0});							#mimick confirmCancel Button press

###these bindings not working for some reason
#  $ADD->bind('<Alt-c>' , sub {$ok=-1});
#  $ADD->bind('<Alt-o>' , sub {$ok=1;});

#close the window but not the whole program 
#$WWIDGETS{'ADD'}->bind('<Control-Key-w>' =>sub {$WWIDGETS{'ADD'}->destroy();  $WWIDGETS{'ADD'}="";}  );


# You probably want to set a grab. See the Tk::FBox source code for
# more information (search for grabCurrent, waitVariable and
# grabRelease).
 $self->{'f_ADD'}->waitVariable(\$ok);		#sleep until the variable changes value =)

 return ($ok==1) ? $curr_dir : "";  #update the folderEntry text box?

}#end buildGUI

 return 1;

__END__