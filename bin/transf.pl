#adition to log file if i have more time
$| = 1;
$sDir = "z:\\";
#-d $sdir || die "can not open Z: disk, makesure the disk is connected!";
$dDir = "E:\\";
-d $dDir || die "can not open distination folder for backup: $dir!";

my ( @grandDir, @fatherDir );
my $folderName;
&getDate();



my $tmpGrandDirFile = $dDir."tmpGrandDir.txt";
my @args = ("dir", "$sDir",  ">","$tmpGrandDirFile" );
system( @args ) == 0 || die "can not create temp file: tmpGrandDir.txt!";
&readDirGrand();




################################11111111111111111111111111######################################################
####
####start to create bat file for make distination folders and need to copy files list
####
################################

foreach my $tmpGrandDir ( @grandDir ){
	chomp $tmpGrandDir;
	
	my $tmpFatherDirFile = $dDir."tmpFatherDir.txt";
	
	my @args = ( "dir", "$tmpGrandDir", ">", "$tmpFatherDirFile" );
	system( @args ) == 0 || die "can not create temp file: tmpFatherDir.txt!";
	&readDirFather( $tmpGrandDir );
	
}
foreach my $tmpFatherDir ( @fatherDir ){
	chomp $tmpFatherDir;

	my $tmpSonDirFile = $dDir."tmpSonDir.txt";
	my @args = ( "dir", "\/OD", "$tmpFatherDir", ">", "$tmpSonDirFile" );
	system( @args ) == 0 || die "can not create temp file: tmpSonDir.txt!";

	&createFolderBat( $tmpFatherDir );
	close( Folder );
	open( Files, ">>".$dDir."tmpCopyFileBat.bat" ) || die "can not create file: tmpCopyBat.bat!";
	&readDirSon( $tmpFatherDir );
	close( Files );
}



######################################
###
###create file tmpCreateFolderBat.bat
###
######################################
sub createFolderBat(  ){

	my ($tmpDir) = @_;
	open( Folder, ">>".$dDir."tmpCreateFolderBat.bat" ) || die "can not create file: tmpCreateFolderBat.bat!";
	print Files "echo off"."\n";
	$tmpDir =~ s/^z://;
	if( -e "e:\\csvBackup".$tmpDir.$folderName ){  return 0; }
	print Folder  "mkdir"."\t"."e:\\csvBackup".$tmpDir.$folderName."\n";
	close( Folder );
}







#######################################
####
####return all model folders list like "z:\96781BTA\" and make a list for copy
####
########################################

sub readDirGrand(){
		
	open( Grand, $dDir."tmpGrandDir.txt" ) || die "can not open file: tmpGrandDir.txt!";
	while(<Grand>){
		my $line = $_;
		my @list = split /[\s\t]+/, $line;
		
		chomp $list[0];
		chomp $list[3];
		chomp $list[4];	
		if( $list[0] =~ /\d{2}\/\d{2}\/\d{2}/ ){
			if( $list[3] =~ /\<DIR\>/ ){
				if( $list[4] =~ /1[ABCD][BT]A$/ ){
					push @grandDir, $sDir.$list[4]."\\";
				}
			}
		}
		
	}
	close( Grand );
}





########################################
####
####return Folders list like "z:\96781BTA\csv\"
####
########################################

sub readDirFather(  ){

	my ( $tmpScale ) = @_;
	open( Father, $dDir."tmpFatherDir.txt" ) || die "can not open file: tmpFatherDir.txt!";

	while( <Father> ){
		my $line = $_;
		my @date_time = localtime();
		
		my @list = split /[\s\t]+/, $line;
		
		chomp $list[0];
		chomp $list[3];
		chomp $list[4];	
		if( $list[0] =~ /\d{2}\/\d{2}\/\d{2}/ && $list[3] =~ /\<DIR\>/ && $list[4] =~ /CSV/  ){
			my @tmpList = split /\//, $list[0];
			chomp $tmpList[0];
			chomp $tmpList[1];

			if( $tmpList[0] == ($date_time[4]+1) && ($tmpList[1]) == $date_time[3] ){
				push @fatherDir, $tmpScale."CSV\\";

			}
		}
	}
	close( Father );
}



########################################
####
####make a copy list files  like "copy z:\96781BTA\csv\98981BTA.F.T.FDO11320Q4B.46be463d.spi.csv e:\..."
####
########################################

sub readDirSon(  ){
	
	my ($copyDir) = @_;

	open( Son, $dDir."tmpSonDir.txt" ) || die "can not open file: tmpSonDir.txt!";
	print Files "echo off"."\n";
	while( <Son> ){
		my $line = $_;
		my @date_time = localtime();

		my $tmpCopy = $copyDir;
		$tmpCopy =~ s/^z://;

		
		chomp( $line );
		
	
		if( $line =~ /\d{2}\/\d{2}\/\d{2}/ ){
			
			my @tmpList = split /\//, $line;

			if( ($tmpList[0] == $date_time[4]+1) && ($tmpList[1] == $date_time[3]) ){

				if( $line =~ /\d+1[ABCD][BT]A.+csv/ ){
					
					print Files  "copy"."\t"."\"".$copyDir.$&."\""."\t"."e:\\csvBackup".$tmpCopy.$folderName."\\"."\n";
				}
			}
		}

	}
	close( Son );
}






####################################222222222222222222222222222222222##########################################
####
####exeuting bat file make distination folders
####
####################################

my $tmpCreateFolderBat = $dDir."tmpCreateFolderBat.bat";

if(-e $tmpCreateFolderBat && !(-z $tmpCreateFolderBat)){
my @args = ( "$tmpCreateFolderBat" );
system( @args ) == 0 || die "excuting bat file:$tmpCreateFolderBat failed!" ;
&deleteFile( $tmpCreateFolderBat );
}                                           


#exeuting bat file for copy each source files to distination folders

my $tmpCopyBat = $dDir."tmpCopyFileBat.bat";

if(-e $tmpCopyBat && !(-z $tmpCopyBat)){
my @args = ( "$tmpCopyBat" );
system( @args ) == 0 || die "excuting bat file:$tmpCopyBat failed!";
&deleteFile( $tmpCopyBat );
}

&deleteFile( $dDir."tmpFatherDir.txt" ); 
&deleteFile( $dDir."tmpGrandDir.txt" ); 
&deleteFile( $dDir."tmpSonDir.txt" );
&deleteFile( $tmpCreateFolderBat ) if( -e $tmpCreateFolderBat );    
&deleteFile( $tmpCopyBat ) if( -e $tmpCopyBat );                                         
#clean the temp file

#############################################################################################################
####
####echo end info
####
########################################
 
print "the program excuting succeesd completed!";






#####################################################################################
###
###get localtime month,day like "0902"
###
########################################

sub getDate(){
	my @date_time = localtime();
	my $month = $date_time[4]+1;
	my $day = $date_time[3];
	 $folderName = $month."-".$day;
		
}

sub deleteFile(  ){
	my ($tmpDelete) = @_;
	my @args = ( "del", "$tmpDelete" );
	system( @args ) == 0 || die "excuting bat file:$tmpCopyBat failed!";

}


