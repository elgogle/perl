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
#use constant MODEL		=> scalar 'cisco4_12';
use constant MODEL		=> scalar 'ciscoC8';

#open log file

open(LOG, ">>" . LOGFILE) or die "can not open logfile";
&getDateTime();


use constant LOCALDATDIR	=> scalar 'c:/cpi/cad';
use constant LOCALOCVDIR	=> scalar 'c:/cpi/data/Ocv/Models/';
use constant LOCALGPMDIR	=> scalar 'c:/cpi/data/Gpm/Models/';
use constant REMOTEDIR		=> scalar 'z:/';

my %waitDat;

if(!( -d LOCALDATDIR )){ &outputToLog( "LOCALDATDIR folder can not find" ); die "LOCALDATDIR folder can not find"; }
if(!( -d LOCALOCVDIR )){ &outputToLog( "LOCALOCVDIR folder can not find" ); die "LOCALOCVDIR folder can not find\n"; }
if(!( -d LOCALGPMDIR )){ &outputToLog( "LOCALGPMDIR folder can not find" ); die "LOCALGPMDIR folder can not find\n"; }
if(!( -d REMOTEDIR )){ &outputToLog( "REMOTEDIR folder can not find" ); die "REMOTEDIR folder can not find\n"; }


#############################  update database file   ##############################
my $modelDatName = MODEL."\.dat";
my $modelAltName = MODEL."\.alt";

my $repositoryDir = REMOTEDIR.MODEL."/Dat";  		#$repositoryDir = z:/cisco4_12/Dat
my $rDatDir = &getRepository( $repositoryDir );  	#$rDatDir = z:/cisco4_12/Dat/56183354
my $rDatFile = "$rDatDir/$modelDatName";  		#$rDatFile = z:/cisco4_12/Dat/56183354/cisco4_12.dat
my $newRDatDir = &makeRandomDir( $repositoryDir );	#$newRDatDir = z:/cisco4_12/Dat/$mon$date$time
my $lDatFile = LOCALDATDIR."/$modelDatName";		#$lDatFile = c:/cpi/cad/cisco4_12.dat
my $tDatFile = TEMPFILE."/$modelDatName";		#$tDatFile = c:/localtemp/cisco4_12.dat

&comp_database( $lDatFile, $tDatFile );			#&comp_database() function return hash %wait
my $newRDatFile = $newRDatDir."/$modelDatName";		#$newRDatFile = z:/cisco4_12/Dat/$mon$date$time/cisco4_12.dat
&refreshDatabaseFile( $newRDatFile, $rDatFile);		#&refreshDatabaseFile() function write new dat file	

############################   Copy Ocv&Gpm file      ##############################
my $LOCALOCVDIR = LOCALOCVDIR.MODEL;			#$LOCALOCVDIR = c:/cpi/data/Ocv/Models/cisco4_12
my $LOCALGPMDIR = LOCALGPMDIR.MODEL;			#$LOCALGPMDIR = c:/cpi/data/Gpm/Models/cisco4_12
my $REMOTEOCVDIR = REMOTEDIR.MODEL."/Ocv";		#$REMOTEOCVDIR = z:/cisco4_12/Ocv
my $REMOTEGPMDIR = REMOTEDIR.MODEL."/Gpm";		#$REMOTEGPMDIR = z:/cisco4_12/Gpm
#&checkOcvGpm() function return array of file list for copy to repository
my ( $ocvArrayRef, $gpmArrayRef ) = &checkOcvGpm( $LOCALOCVDIR, $LOCALGPMDIR, $REMOTEOCVDIR, $REMOTEGPMDIR );
&copyOcvGpmFiles( $ocvArrayRef, $gpmArrayRef );

############################   update alt file      ##############################
my $laltf = LOCALDATDIR."/".$modelAltName;		#$laltf = c:/cpi/cad/cisco4_12.alt
my $taltf = TEMPFILE."/".$modelAltName;			#$taltf = c:/localtemp/cisco4_12.alt
my $raltf = "$rDatDir/$modelAltName";			#$raltf = z:/cisco4_12/Dat/56183354/cisco4_12.alt
my $naltf = "$newRDatDir/$modelAltName";		#$naltf = z:/cisco4_12/Dat/$mon$date$time/cisco4_12.alt

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
	my $mon		= $date_time[4] + 1;					#jan is 0 dec is 11
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
##update alt file
##
################################################

sub refreshAltFile{
	my( $lalt, $talt, $ralt, $nalt ) = @_;
	my( %hlalt, %htalt, %hralt );
	my %waitAlt;
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
			if( ${$hlalt{$k}} ne ${$htalt{$k}} ){ ${$waitAlt{$k}} = ${$hlalt{$k}}; }
		}else{
			${$waitAlt{$k}} = ${$hlalt{$k}};
		}	
	}
#clean hash %hlalt and %htalt
	undef %htalt;
	undef %hlalt;
	
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
	foreach my $k ( keys %waitAlt ){
		if ( !(exists ( $hralt{$k} )) ){ 
			${$hralt{k}} = ${$waitAlt{$k}};
			&outputToLog($k);
		}
	}
	&outputToLog( "--------------------------------------------------------------------------------" );
	open(nALT, ">".$nalt) or ( &outputToLog("can not open $nalt!") and die "can not open $nalt!" );
	&outputToLog("open file: $nalt succeed!");
	foreach my $k ( keys %hralt ){
		print nALT $k."\n";
		print nALT ${$hralt{$k}}."\n";
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
	undef @locvDir;
	undef @rocvDir;
	undef @lgpmDir;
	undef @rgpmDir;
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
		&outputToLog( "copy ocv file:$sof succeed!" );
	}else{	
		 &outputToLog( "copy ocv file:$sof failed: $!" );
		 die "copy ocv file failed: $!";
	}
  }
  foreach my $sgf ( @{$sGpmFile} ){
	if( copy("$LOCALGPMDIR/$sgf", "$REMOTEGPMDIR/$sgf") ){
		&outputToLog( "copy gpm file:$sgf succeed!" );
	}else{
		&outputToLog( "copy gpm file:$sgf failed: $!" );
		die "copy gpm file failed: $!";
	}
  }
}

#################################################
###
###return Repository recent update directory
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
	
    	if(!( -e "$remoteFileDir/$modelDatName" ) ){ 
		&outputToLog( "can not find dat file in $remoteFileDir folder!" );
		die "can not find dat file in $remoteFileDir folder!";
	}

	return "$remoteFileDir";	
}

##################################################
###
###Refresh Dat file
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
	undef @aRDB;
	close RDB;
	
	&outputToLog( "--------------------follow partnum Algorithm has been update-------------------\n" );
	foreach my $w ( sort keys %waitDat ){
		&outputToLog( $w );
		@{$hRDB{$w}} = @{$waitDat{$w}};
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
##Create folder for refresh dat & alt files
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
##compare dat file
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
	undef @aLDBA;
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
	undef @aTDBA;
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

			if( $lstr ne $tstr ){ 
				@{$waitDat{$key}} = @{$hLDBA{$key}};
			}
			
		}else{ 
			@{$waitDat{$key}} = @{$hLDBA{$key}};
		}
	}
#clean hash %hLDBA and %hTDBA
	undef %hLDBA;
	undef %hTDBA;
	
}


############### close network ################
if(  -d "z:/"  ){
my @args1 = ( "net", "use", "z:", "/DELETE" );
system ( @args1 ) == 0 or die "system @args1 failed: $?";
}