#!/usr/bin/perl -W

use strict;
use File::Path;
use File::Copy;
use Sys::Hostname;


############### connect network ################
if( !( -d "z:/" ) ){
my @args = ( "net", "use", "z:","\\\\172.30.143.109\\c\$\\liaoshujun\\auto\\database", "Agilent602", "/USER:cpi" );
system ( @args ) == 0 or die "system @args failed: $?";
}

use constant LOGFILE		=> scalar 'z:/log/updateDatabase.log';
use constant TEMPFILE		=> scalar 'c:/localtemp';

#open log file

open(LOG, ">>" . LOGFILE) or die "can not open logfile";
&getDateTime();

#@existDifDevice; for later use
#@newDifDevice;  for later use


my $LOCALDIR = "c:/cpi/cad";
my $REMOTEDIR = "z:/dat";
my $MODEL = "cisco4_12.dat";
my $LOCALOCVDIR = "c:/cpi/data/Ocv/Models/cisco4_12";
my $REMOTEOCVDIR = "z:/Ocv";
my $LOCALGPMDIR = "c:/cpi/data/Gpm/Models/cisco4_12";
my $REMOTEGPMDIR = "z:/gpm";
my $LOCALALT = "cisco4_12.alt";
my %wait;

if(!( -d $LOCALDIR )){ &outputToLog( "$LOCALDIR folder can not find" ); die "$LOCALDIR folder can not find"; }
if(!( -d $REMOTEDIR )){ &outputToLog( "$REMOTEDIR folder can not find" ); die "$REMOTEDIR folder can not find\n"; }




#############################  update database file   ##############################
my $rd = &getRepository( $REMOTEDIR );
my $rf = $rd.$MODEL;
my $newRf = &makeRandomDir( $REMOTEDIR );
my $lf = "$LOCALDIR/$MODEL";
my $tf = TEMPFILE."/$MODEL";

&comp_database( $lf, $tf );
&refreshDatabaseFile( "$newRf/$MODEL", $rf);

############################   Copy Ocv&Gpm file      ##############################
my ( $ocvArrayRef, $gpmArrayRef ) = &checkOcvGpm( $LOCALOCVDIR, $LOCALGPMDIR, $REMOTEOCVDIR, $REMOTEGPMDIR );
&copyOcvGpmFiles( $ocvArrayRef, $gpmArrayRef );

############################   update alt file      ##############################
my $rAltFile = "$newRf/$LOCALALT";
#&copyAltFile( $rAltFile );
my $laltf = "$LOCALDIR/$LOCALALT";
my $taltf = TEMPFILE."/$LOCALALT";
my $raltf = $rd.$LOCALALT;
my $naltf = "$newRf/$LOCALALT";

&refreshAltFile( $laltf, $taltf, $raltf, $naltf );
&outputToLog( "############################################################################\n\n\n" );
close LOG;

################################################
##
##output log
##
################################################
sub getDateTime{

	my @date_time = localtime();
	
	#local_time() returns array containing:
	#   0    1    2     3     4    5     6     7     8
    #($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)

	#date parts
	my $day		= $date_time[3];
	my $mon		= $date_time[4] + 1;								#jan is 0 dec is 11
	my $year	= sprintf("%02d", ($date_time[5] + 1900) % 100);	#year is number of years since 1900
	
	#create correct date format	mm/dd/yy
	my $date = $mon . "/" . $day . "/" . $year;

	#time parts
	my $sec		= $date_time[0];
	my $min		= $date_time[1];
	my $hour	= $date_time[2];
	
	if (length($hour) == 1) { $hour	= "0" . $hour;	}
	if (length($min) == 1) { $min	= "0" . $min;	}
	if (length($sec) == 1) { $sec	= "0" . $sec;	}

	#create time in correct format
	my $time = $hour . ":" . $min . ":" . $sec;
	my $hostname = hostname( );
	&outputToLog("------------------follow log created by $hostname------------------\n");
	&outputToLog($date . " " . $time);

}
sub outputToLog{
	
	my($string) = @_;
	
	print LOG "$string\n";

}

################################################
##
##Copy alt file
##
################################################
#sub copyAltFile{
#	my ($laltf) = @_;
#	if( -e "$LOCALDIR/$LOCALALT" ){
#		if( !( copy( "$LOCALDIR/$LOCALALT", "$laltf" ) ) ) {  
#			&outputToLog( "copy alt file failed!");
#			die "copy alt file failed: $!"; 
#		}
#		&outputToLog( "copy alt file succeed!");
#	}
#}
sub refreshAltFile{
	my( $lalt, $talt, $ralt, $nalt ) = @_;
	my( %hlalt, %htalt, %hralt );
	my %wait;
	open( LAF, $lalt ) or ( &outputToLog( "can not open $lalt file!" ) and die "can not open $lalt file!"  );
	&outputToLog( "open $lalt file!");
	open( TAF, $talt ) or ( &outputToLog( "can not open $talt file!" ) and die "can not open $talt file!" );
	&outputToLog( "open $talt file!");
	open( RAF, $ralt ) or ( &outputToLog( "can not open $talt file!" ) and die "can not open $talt file!" );
	&outputToLog( "open $ralt file!");
	
	my $device = '';
LOOP1:	while(<LAF>){
		chomp;
		my $tmp = $_;
		my @split = split/[ \t]+/,$tmp;
		if($split[0] eq "a"){

			$device = $tmp;
			${$hlalt{$device}} = '';
			next LOOP1;
		}
		if( ($device ne "") and ($tmp ne "") ){ ${$hlalt{$device}} = $tmp; }
	}
	close LAF;
	
	$device = '';
LOOP2:	while(<TAF>){
		chomp;
		my $tmp = $_;
		my @split = split/[ \t]+/,$tmp;
		if($split[0] eq "a"){

			$device = $tmp;
			${$htalt{$device}} = '';
			next LOOP2;
		}
		if( ($device ne "") and ($tmp ne "") ){ ${$htalt{$device}} = $tmp; }
	}
	close TAF;
	
	foreach my $k ( keys %hlalt ){
		if ( exists ( $htalt{$k} )){
			if( ${$hlalt{$k}} ne ${$htalt{$k}} ){ ${$wait{$k}} = ${$hlalt{$k}}; }
		}else{
			${$wait{$k}} = ${$hlalt{$k}};
		}	
	}
#clean hash %hlalt and %htalt

	$device = '';
LOOP3:	while(<RAF>){
		chomp;
		my $tmp = $_;
		my @split = split/[ \t]+/,$tmp;
		if($split[0] eq "a"){

			$device = $tmp;
			${$hralt{$device}} = '';
			next LOOP3;
		}
		if( ($device ne "") and ($tmp ne "") ){ ${$hralt{$device}} = $tmp; }
	}
	&outputToLog( "--------------follow partnum Algorithm has been update for alt file-------------\n" ); 
	foreach my $k ( keys %wait ){
		if ( !(exists ( $hralt{$k} )) ){ 
			${$hralt{k}} = ${$wait{$k}};
			&outputToLog($k);
		}
	}
	&outputToLog( "--------------------------------------------------------------------------------" );
	open(nALT, ">".$nalt) or ( &outputToLog("can not open $nalt!") and die "can not open $nalt!" );
	&outputToLog("open file: $nalt succeed!");
	foreach my $k ( keys %hralt ){
		print nALT $k."\n";
		print nALT ${$hralt{$k}};
	}

close RAF;
close nALT;
}

################################################
##
##check ocv and gpm file list
##
################################################
sub checkOcvGpm{
	my ( $locv, $lgpm, $rocv, $rgpm ) = @_;
	my ( @locvDir, @lgpmDir, @rocvDir, @rgpmDir );

###read specify directory and push list to array

	opendir(BIN, $locv) or ( &outputToLog( "Can't open $locv: $!" ) and die "Can't open $locv: $!" );
	&outputToLog( "open $locv succeed !" );
	while( my $file = readdir BIN) {
    		push( @locvDir, $file);
	}
	closedir(BIN);
	opendir(BIN, $rocv) or ( &outputToLog( "Can't open $rocv: $!" ) and die "Can't open $rocv: $!" );
	&outputToLog( "open $rocv succeed !");
	while( my $file = readdir BIN) {
    		push( @rocvDir, $file);
	}
	closedir(BIN);
	opendir(BIN, $lgpm) or ( &outputToLog( "Can't open $lgpm: $!" ) and die "Can't open $lgpm: $!" );
	&outputToLog( "open $lgpm succeed !");
	while( my $file = readdir BIN) {
    		push( @lgpmDir, $file);
	}
	closedir(BIN);
	opendir(BIN, $rgpm) or ( &outputToLog( "Can't open $rgpm: $!" ) and die "Can't open $rgpm: $!" );
	&outputToLog( "open $rgpm succeed !" );
	while( my $file = readdir BIN) {
    		push( @rgpmDir, $file);
	}
	closedir(BIN);

###compare file list

	my $flag = 0; 
	my @cpOcvList;
	my @cpGpmList;
	foreach my $lotemp ( @locvDir ){
			foreach my $rotemp ( @rocvDir ){
				$flag = 1;
				$flag = 0 if ( $rotemp eq $lotemp );
				last if ( $rotemp eq $lotemp );
			}
		push @cpOcvList, $lotemp if $flag eq 1; 
	}
	foreach my $lgtemp ( @lgpmDir ){
		foreach my $rgtemp ( @rgpmDir ){
			$flag = 1;
			$flag = 0 if $lgtemp eq $rgtemp;
			last if $lgtemp eq $rgtemp;
		}
		push @cpGpmList, $lgtemp if $flag eq 1;
	}
	return \@cpOcvList, \@cpGpmList;
}


#################################################
##
##copy specify Ocv&Gpm files
##
#################################################
sub copyOcvGpmFiles{
	my( $sOcvFile, $sGpmFile ) = @_;

  foreach my $sof ( @{$sOcvFile} ){
	if ( copy("$LOCALOCVDIR/$sof", "$REMOTEOCVDIR/$sof") ){ 
		&outputToLog( "copy ocv file succeed!" );
	}else{	
		 &outputToLog( "copy ocv file failed: $!" );
		 die "copy ocv file failed: $!";
	}
  }
  foreach my $sgf ( @{$sGpmFile} ){
	if( copy("$LOCALGPMDIR/$sgf", "$REMOTEGPMDIR/$sgf") ){
		&outputToLog( "copy gpm file succeed!" );
	}else{
		&outputToLog( "copy gpm file failed: $!" );
		die "copy gpm file failed: $!";
	}
  }
}

#################################################
###
###
###
#################################################
sub getRepository{
	my( $remoteDir ) = @_;
	my @dir;
	my $rFile = "";
	opendir(BIN, $remoteDir) or ( &outputToLog( "Can't open $remoteDir: $!" ) and  die "Can't open $remoteDir: $!" );
	&outputToLog( "open $remoteDir succeed!" );
	while( my $file = readdir BIN) {
    		push( @dir, $file) if -d "$remoteDir/$file";
	}
	closedir(BIN);
	@dir = sort @dir;

	my $remoteFileDir = "$remoteDir/$dir[$#dir]";
	
    	if(!( -e "$remoteFileDir/$MODEL" ) ){ 
		&outputToLog( "can not find dat file in $remoteFileDir folder!" );
		die "can not find dat file in $remoteFileDir folder!";
	}

	return "$remoteFileDir/";	
}

##################################################
###
###
###
##################################################
sub refreshDatabaseFile {

	my( $newfile, $repositoryDatabase ) = @_;

	my @aRDB;
	my %hRDB;
	my $DEVICE;

	open( Refresh, ">".$newfile ) or ( &outputToLog( "can not open file: $newfile!" ) and die "can not open file: $newfile! \n" );
	&outputToLog( "open file $newfile succeed!" );


	if ( open(RDB, $repositoryDatabase) ){
		&outputToLog( "open $repositoryDatabase file succeed!" );
	}else{
		&outputToLog( "can not open $repositoryDatabase file!" );
		die "can not open $repositoryDatabase file!";
	}
	
	@aRDB = <RDB>;
LOOP1:	foreach my $l ( @aRDB ){
		my @split = split/[ \t]+/,$l;
		chomp $l;
		#print $l."\n";
		next if(substr($split[0], 0, 1) eq "!");
		next if(substr($split[0], 0, 1) eq "#");
		
		if($split[0] eq "USER"){
			$DEVICE = $l;

			@{$hRDB{$DEVICE}} = ();
			next LOOP1;
		}
		if( ($DEVICE ne "") and ($l ne "") ){ push @{$hRDB{$DEVICE}}, $l; }
	}
	close RDB;
	&outputToLog( "--------------------follow partnum Algorithm has been update-------------------\n" );
	foreach my $w ( sort keys %wait ){
		&outputToLog( $w );
		@{$hRDB{$w}} = @{$wait{$w}};
	}
	&outputToLog( "-------------------------------------------------------------------------------" );
	foreach my $p ( sort keys %hRDB ){
		print Refresh $p."\n";

		foreach my $k ( @{$hRDB{$p}} ){
			print Refresh $k."\n";
		}
		print Refresh "\n";
	}
close ( Refresh );

}

################################################
##
##
##
###############################################
sub makeRandomDir{
	my( $dir ) = @_;       
	my @date_time = localtime();
	my $day	= $date_time[3];
	my $mon	= $date_time[4] + 1;
	#time parts
	my $sec		= $date_time[0];
	my $min		= $date_time[1];
	my $hour	= $date_time[2];
	
	if (length($hour) == 1) { $hour	= "0" . $hour;	}
	if (length($min) == 1) { $min	= "0" . $min;	}
	if (length($sec) == 1) { $sec	= "0" . $sec;	}

	my $tmpDir = "$dir/$mon$day$hour$min$sec";
	&createDirectory( $tmpDir );
	return $tmpDir;
}
sub createDirectory{
	my($dir) = @_;
	
	eval { mkpath($dir) };
  	if ($@) {
		&outputToLog( "Couldn't create $dir: $@" );
    		die "Couldn't create $dir: $@";
  	}

}

##############################################
##
##
##
##############################################
sub comp_database{

	my( $localDatabase, $tempDatabase ) = @_;
	my( @aLDBA, @aTDBA );
	my %hLDBA;
	my %hTDBA;
	my $device;

	if ( open(LDB, $localDatabase) ){
		&outputToLog( "open $localDatabase file succeed!" );
	}else{
		&outputToLog( "can not open $localDatabase file!" );
		die "can not open $localDatabase file!";
	}
	if ( open(TDB, $tempDatabase) ){
		&outputToLog( "open $tempDatabase file succeed!" );
	}else{
		&outputToLog( "can not open $tempDatabase file!" );
		die "can not open $tempDatabase file!";
	}
		

	@aLDBA =  <LDB>;
LOOP1:	foreach my $l ( @aLDBA ){
		my @split = split/[ \t]+/,$l;
		chomp $l;

		next if(substr($split[0], 0, 1) eq "!");
		next if(substr($split[0], 0, 1) eq "#");
		
		if($split[0] eq "USER"){
			$device = $l;

			@{$hLDBA{$device}} = ();
			next LOOP1;
		}

		if( ($device ne "") and ($l ne "") ) { push @{$hLDBA{$device}}, $l; }

	}
	close LDB;



	@aTDBA =  <TDB>;
	$device = '';
LOOP2:	foreach my $r ( @aTDBA ){
		my @split = split/[ \t]+/,$r;
		chomp $r;

		next if(substr($split[0], 0, 1) eq "!");
		next if(substr($split[0], 0, 1) eq "#");
		

		if($split[0] eq "USER"){

			$device = $r;
			@{$hTDBA{$device}} = ();
			next LOOP2;
		}
		
		if( ($device ne "") and ($r ne "") ) { push @{$hTDBA{$device}}, $r; }
	}
	close TDB;

	foreach my $key ( keys %hLDBA ){
		my $lstr = "";
		my $tstr = "";
		if ( exists $hTDBA{$key} ){

			foreach  my $temp ( @{$hLDBA{$key}} ){
				chomp( $temp );
				 $lstr .= $temp;

			}
			foreach my $temp ( @{$hTDBA{$key}} ){
				chomp( $temp );
				$tstr .= $temp;
			}

			$lstr =~ s/[ \t]*//g;

			$tstr =~ s/[ \t]*//g;

			if( $lstr ne $tstr ){ #push @existDifDevice, $key;
				@{$wait{$key}} = @{$hLDBA{$key}};
			}
			
		}else{ 
			#push @newDifDevice, $key;
			@{$wait{$key}} = @{$hLDBA{$key}};
			
		}

	}
	#%hRDBA = undef;
	#%hTDBA = undef;

}


############### close network ################
if(  -d "z:/"  ){
my @args1 = ( "net", "use", "z:", "/DELETE" );
system ( @args1 ) == 0 or die "system @args1 failed: $?";
}