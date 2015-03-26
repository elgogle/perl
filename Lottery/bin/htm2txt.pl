use IO::File;   
use Cwd;

$| = 1;
my @fileList;
my @myLottery;
my $dirName = getcwd;


open( TXTFILE, ">>", "htm2txt.txt" ) or die "can't open htm2txt.txt: $!";


opendir(DIR, $dirName) or die "can't opendir $dirname: $!";
while (defined($file = readdir(DIR))) {
	if( $file =~ m/.htm$/g ){
		push @fileList, $file;
	}
}
closedir(DIR);

foreach my $fileName ( @fileList ){
    my $content;	
    $fh = new IO::File;
    print $fileName."\n";
    if ($fh->open("< $fileName")) {
    	while ( <$fh> ){ $content .= $_; }
	storeLottery( $content );
	$fh->close;
    }
}

sub storeLottery{
	my ( $strings ) = @_;
	@list = $strings =~ m/\d{2}\s[\d\s]*\d{2}\s\d{2}:[\d\s]*\d{2}/g;
	push @myLottery, @list;
}

foreach my $a ( @myLottery ){
	print  TXTFILE "$a\n";
}

close( TXTFILE );