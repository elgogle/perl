#!/perl/bin
#use strict;
use warnings;
use Cwd;

my $dir = getcwd();
my @files;
my %red;
my %blue;
my @ss;


#read special files
opendir(DIR, $dir) or die "can't opendir $dir: $!";
while (defined($file = readdir(DIR))) {
	if( $file =~ /\d+/i){
		push(@files,$file);
		}
}
closedir(DIR);
#sort(@files);

foreach my $name ( @files){
	open(FILE, $name) or die "can't open $name:$!";
	while(<FILE>)
	{
		my $line = $_;
		my @sRed = ();
		my @sBlue = ();
		chomp($line);
		my ($red,$blue) = split(/:/,$line);
		chomp($red);
		chomp($blue);
		@sRed = split(/\s+/,$red);
		@sBlue = split(/\s+/,$blue);
		if( scalar(@sRed) <=6){	
			my $i = 0;
			foreach my $num (@sRed){
				$i++;
				print "$i: $num\n";
				${$red{$i}{$num}}+=1;
				#${$red{$i{$num}}}+=1;
				
			}
			if( scalar(@sBlue) == 1){
				foreach my $num (@sBlue){
					${$blue{$num}}+=1;
					
				}	
			}else{ push( @ss, $line); }
		}else{push(@ss,$line);}
		
	}
	close(FILE);
}
sub by_numric{
if   ($a<$b)   {  
  return   -1;  
  }elsif   ($a==$b){  
  return   0;  
  }elsif   ($a>$b){  
  return   1;  
  } 
}

open ( FILE, ">MyCaipiao.txt") || die "can't create file:MyCaipiao.txt\n";
print FILE "-----------------------------Red----------------------------------\n";
foreach my $a ( sort by_numric  (keys %red)){
	{
		print FILE "-------------------$a--------------------\n";
		
		foreach my $b ( sort by_numric (keys %{$red{$a}} ) ){
			
			if( ${$red{$a}{$b}} != 0){
				print FILE "$b:${$red{$a}{$b}}\n";
			}	
		}
			
	}
}
print FILE "-----------------------------Blue----------------------------------\n";
foreach my $b ( sort by_numric  (keys %blue)){
	if( ${$blue{$b}} != 0 ){
		print FILE "$b:${$blue{$b}}\n";
	}
}
print FILE "----------------------------Duplex---------------------------------\n";
while(my $b = pop(@ss)){
	print FILE "$b\n";	
}
close(FILE);
