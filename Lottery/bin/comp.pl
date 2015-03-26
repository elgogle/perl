my %hashList;
open( FILE, "<htm2txt.txt" ) or die "can't open file:$!\n";
open( COMP, ">COMP.txt" ) or die "can't open file:$!\n";
while(<FILE>){
	my $line = $_;
	chomp( $line );
	${$hashList{$line}}++;
}

foreach my $key (sort { ${$hashList{$a}} cmp ${$hashList{$b}} } keys %hashList ){
	if( ${$hashList{$key}} > 1 ){
		print COMP "$key => ${$hashList{$key}}\n";
	}
}