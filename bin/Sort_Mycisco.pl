$| = 1;
$pa3 = "E:\\liaoshujun\\Data_cisco\\Reports\\Defects\\";

chomp $pa3;
-d $pa3 || die "can not open dir:$!";

my $surcefile  = $pa3."Mycisco.txt";
chomp $surcefile;
open(Mycisco, $surcefile) || die "can not open file: $surcefile"; 

while( <Mycisco> ){
     $Line = $_;
     my @spline = split /[\t]+/, $Line;
  
     if( $spline[0] =~ /^[Ff][Dd][Oo]+/ ){
	if( $spline[1] =~ /^\d+\w\w\w$/ ){
		my $side = ( $spline[1] =~ /[Tt]/g ) ? top : bot;
		$spline[1] =~ s/\d{1}\w{3}$//;
		my $name = $spline[1];
		chomp $name;
	
		my $destinationfile = $pa3.$name.".txt";
		chomp $destinationfile;
		$spline[5] =~ s/\s\d{2}:\d{2}:\d{2}\.\d+$//;
		my $date = $spline[5];
		chomp $date;

		open( SplitFile, ">>".$destinationfile  ) || die "can not create file: $destinationfile";
		print SplitFile $date.",".$name.",".$side.",".$spline[0].",".$spline[3].",".$spline[2]."\n";
		
	  
	}
     }
}
close SplitFile;
close Mycisco;
