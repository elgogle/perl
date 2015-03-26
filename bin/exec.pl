
$| = 1;
print "please input datetime like this \"0901-0906\"\n";
open( FSQL, "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\Query_MyciscoFalse.sql" ) || die "can not open file: $!";
#open( SQL, "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\Query_Mycisco.sql" ) || die "can not open file: $!";
my ( $fbm, $fbd, $fam, $fad );
while(<>){
	my $line = $_;
	chomp( $line );

	if( $line =~ /^\d{4}-\d{4}$/ ){
		$line =~ s/-//;
		my @sp = split //, $line ;
		if( $sp[0] == 1 ){ 
			if( $sp[1] =~ /[012]/ ){ 
La2:				if( $sp[2] == 3 ){ 
					if( $sp[3] =~ /[01]/ ){ 
La4:						if( $sp[4] == 1 ){
							if ( $sp[5] =~ /[012]/ ){
La6:								if( $sp[6] == 3 ){
									if( $sp[7] =~ /[01]/ ){
La8:										$fbm = $sp[0].$sp[1];
										$fbd = $sp[2].$sp[3];
										$fam = $sp[4].$sp[5];
										$fad = $sp[6].$sp[7] + 1;
										last;
									}
								}elsif( $sp[6] =~ /[12]/ ){
									if( $sp[7] =~ /[0-9]/ ){
										goto La8;
									}
								}elsif( $sp[6] == 0 ){
									if( $sp[7] =~ /[1-9]/ ){
										goto La8;
									}
								}
							}
						}elsif( $sp[4] == 0 ){
							if ( $sp[5] =~ /[1-9]/ ){
								goto La6;
							}
						}
					}
				}elsif( $sp[2] =~ /[12]/ ){ 
					if( $sp[3] =~ /[0-9]/ ){ 
						goto La4;					
					}		
				}elsif( $sp[2] == 0 ){
					if ( $sp[3] =~ /[1-9]/ ){
						goto La4;
					}
				}
			}
		}elsif( $sp[0] == 0 ){ 
			if( $sp[1] =~ /[1-9]/ ){ 
				goto La2;
			}
		}
		
	}
	print "please input datetime like this \"0901-0906\"\n";	
}

open( tmpFSQL, ">>"."E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\A.sql" ) || die "can not open file: $!";
#open( tmpSQL, ">>"."E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\B.sql" ) || die "can not open file: $!";

while( <FSQL> ){
	my $sline = $_;
	chomp( $sline );
	my @date_time = localtime();
	my $year = ( $date_time[5] + 1900 );

	if( $sline =~ /^set\s\@Db.*/ ){ 
		print tmpFSQL "set \@Db = convert(datetime, \'".$year.$fbm.$fbd."\', 112);\n";
		next;
	}
	if( $sline =~ /^set\s\@Da.*/ ){ 
		print tmpFSQL "set \@Da = convert(datetime, \'".$year.$fam.$fad."\', 112);\n";
		next;
	}
	
	print tmpFSQL $sline."\n";
}

#while( <SQL> ){
#	my $sline = $_;
#	chomp( $sline );
#	my @date_time = localtime();
#	my $year = ( $date_time[5] + 1900 );
#
#	if( $sline =~ /^set\s\@Db.*/ ){ 
#		print tmpSQL "set \@Db = convert(datetime, \'".$year.$fbm.$fbd."\', 112);\n";
#		next;
#	}
#	if( $sline =~ /^set\s\@Da.*/ ){ 
#		print tmpSQL "set \@Da = convert(datetime, \'".$year.$fam.$fad."\', 112);\n";
#		next;
#	}
#	
#	print tmpSQL $sline."\n";
#}

close( FSQL );
#close( SQL );
close( tmpFSQL );
#close( tmpSQL );


@args = ( "osql", "-i", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\A.sql", "-E" );
system( @args ) == 0 || die "system @args failed: $?";

#@args = ( "osql", "-i", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\B.sql", "-E" );
#system( @args ) == 0 || die "system @args failed: $?";

#@args = ( "bcp", "itf.dbo.Mycisco", "out", "E:\\liaoshujun\\Data_cisco\\Reports\\Defects\\Mycisco.txt", "-c", "-U", \"sa\"", "-P", "\"\"");
#system(@args) == 0 || die "system @args failed: $?";

@args = ( "bcp", "itf.dbo.MyciscoFalse", "out", "E:\\liaoshujun\\Data_cisco\\Reports\\FalseCall\\MyciscoFalse.txt", "-c", "-U", "\"sa\"", "-P", "\"\"");
system(@args) == 0 || die "system @args failed: $?";

#@args = ( "perl", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\Sort_Mycisco.txt" );
#system(@args) == 0 || die "system @args failed: $?";

@args = ( "perl", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\Sort_MyciscoFalse.txt" );
system(@args) == 0 || die "system @args failed: $?";



#delete temp file
@args = ( "del", "\/F", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\A.sql" );
system( @args );
#@args = ( "del", "\/F", "E:\\liaoshujun\\Data_cisco\\Defects_Query\\Program\\sql\\B.sql" );
#system( @args );
