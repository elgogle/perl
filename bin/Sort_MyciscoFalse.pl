$| = 1;
$dir = "E:\\liaoshujun\\Data_cisco\\Reports\\FalseCall\\";

chomp $dir;
-d $dir || die "can not open dir:$!";

my $surcefile  = $dir."MyciscoFalse.txt";
chomp $surcefile;
open(Mycisco, $surcefile) || die "can not open file: $surcefile"; 
my %count;

while( <Mycisco> ){
     $Line = $_;
     my @spline = split /[\t]+/, $Line;
  
     if( $spline[0] =~ /^[Ff][Dd][Oo]\d{4}[\d\w]{4}/ ){
	if( $spline[1] =~ /^\d+\w\w\w$/ ){
		my $side = ( $spline[1] =~ /[Tt]/g ) ? top : bot;
		$spline[1] =~ s/\d{1}\w{3}$//;
		my $name = $spline[1];
		chomp $name;
	
		my $destinationfile = $pa3.$name.".txt";
		chomp $destinationfile;
		$spline[3] =~ s/\s\d{2}:\d{2}:\d{2}\.\d+$//;
		my $date = $spline[3];
		chomp $date;

		if( $spline[2] >= 0 && $spline[2] < 25 ){
			$count{$date}{$name}{$side}[0] += $spline[2];
			$count{$date}{$name}{$side}[1]++;
			
		}

		#open( SplitFile, ">>".$destinationfile  ) || die "can not create file: $destinationfile";
		#print SplitFile $date.",".$name.",".$side.",".$spline[0].",".$spline[2]."\n";
		
	   
	}
     }
}

open( FalseCall, ">".$dir."falseCallCount.txt" ) || die "can not open file: falseCallcount.txt"; 
print FalseCall "Date\t\tModel\tSide\tsum(falsecall)\tsum(boards)\tRate\n";

foreach my $d ( keys %count ){
	foreach my $n ( keys %{ $count{ $d } } ){
		foreach my $s ( keys %{ $count{$d}{$n} } ){
			my $rate = $count{$d}{$n}{$s}[0]/$count{$d}{$n}{$s}[1];
			print FalseCall $d."\t".$n."\t".$s."\t".$count{$d}{$n}{$s}[0]."\t\t".$count{$d}{$n}{$s}[1]."\t\t".$rate."\n";
		}
	}
			
}

#close SplitFile;
close FalseCall;
close Mycisco;
