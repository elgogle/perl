#use strict;  
$| = 1;
 
use LWP 5.64;  
use HTML::LinkExtor;
my $browser = LWP::UserAgent->new;  

my $pageMax;
my %linkHash;
my @queue;
my $fileName = 0;

my $url = 'http://caipiao.taobao.com/lottery/order/united_list.htm?';
my $MyHtmlMatch0 = "http://caipiao.taobao.com/lottery/order/united_order_detail.htm.tb_united_id=";
my $MyLinkMatch0 = "http://caipiao.taobao.com/lottery/order/united_detail.htm.united_id=";
my $MyLinkMatch1 = "http://caipiao.taobao.com/lottery/order/united_order_detail.htm.tb_united_id=";

  
open ( LOGFILE, ">>", "log1.txt" ) || die "can't open file log file\n";

#ץȡδ��Աҳ��
$pageMax = getMaxNumber( getHomeFlag1( 1 ) );
OutputLog( "δ��Ա��\$pageMax: $pageMax" );
for( my $i = 1; $i<= $pageMax; $i++)
{
	OutputLog( "���ڻ�ȡ��$iҳ..." );
	getHomeLink( $i );
	my $firstLink = pop @queue;
	recursion( $firstLink );	
}

close LOGFILE;


#���ݹ�
sub recursion
{
       my ( $tmpurl ) = @_;
       my $htmlContent = getHtml( $tmpurl );
       my @link = fetchLink( $htmlContent );
       storeLink2Queue( @link );
       if( length @queue == 1 )
       {
              return;
       }
       else
       {
              my $linked = pop @queue;
              OutputLog( "pop \@queue: ".$linked );
              ${$linkHash{$linked}} = 1;
              recursion( $linked );
       }     
}

#��ȡҳ������
sub getMaxNumber{
	OutputLog( "program on getMaxNumber" );
	my ( $content ) = @_;
	if( $content =~ m/(var\s+max_page\s+=\s+)(\d+)/g ){
		return $2;
	}
}

#�����־�ļ�
sub OutputLog{
	my ( $string ) = @_;
	print LOGFILE $string."\n";
}
 

#ץȡ��ָ����ַҳ�沢�ж���ַ,������ҳ����������
sub getHtml{ 
       OutputLog( "program on getHtml" );
       my ( $raw_url ) = @_;

       my $ua = LWP::UserAgent->new( );
       $ua->agent("Schmozilla/v9.14 Platinum");  
       my $response = $ua->get( $raw_url );
       if ($response->is_error( )) {
		OutputLog( $response->status_line );
       } else {
                my $content = $response->content( );
		if( $raw_url =~ m/$MyHtmlMatch0/g )
		{
			saveHtml( $content );	
		}
                return $content;
       } 
       OutputLog( "could not get $raw_url" );
}
 

#������ҳ���ݲ�ץȡ��Ч����
sub fetchLink{ 
       OutputLog( "program on fetchLink" );
       my ( $htmlContent ) = @_;
       my @MyLinks;

       my $parser = HTML::LinkExtor->new(undef, $url);
       $parser->parse( $htmlContent );
       my @links = $parser->links;

       foreach  my $linkarray (@links) {
                 my @element  = @$linkarray;
                 my $elt_type = shift @element;

                 while (@element) {
                    my ($attr_name , $attr_value) = splice(@element, 0, 2);

                    if ($elt_type eq 'a' && $attr_name eq 'href') 
                    {
                             if ( $attr_value =~ /$MyLinkMatch0|$MyLinkMatch1/g  )
                             {
                                    push @MyLinks, $attr_value;       
                             }
                     }
             }
      }
      return @MyLinks;
}


#�����ɲ����ṩ������ȷ��û�б����ʹ�������Ҫ��Ȼ�����������ʶ�����
sub storeLink2Queue{
	OutputLog( "program on storeLink2Queue" );
	my ( @newLink ) = @_;
	foreach my $a ( @newLink )
	{
		if( defined( $a ) ){
                	if( ${$linkHash{$a}} != 1 ){ 
              			${$linkHash{$a}} = 0;  # '0' δ�����ʣ�'1' �ѷ���
              			push @queue, $a;
				OutputLog( "push Link to \@queue: $a" );              		
              		}
        	}
       }
}


#������ҳ����
sub saveHtml
{
       OutputLog( "program on saveHtml" );
       my ($myHtmlString) = @_;
	open( FILE, ">", "1-$fileName.htm" ) or OutputLog ( "can't open $fileName.htm: $!" );
	print FILE $myHtmlString;
	close( FILE );
	$fileName++;
}

#��ȡָ��ҳ��
sub getHomeLink{ 
	OutputLog( "program on getHomeLink" );
	my ($pageNumber) = @_;
	my $response = $browser->post( $url,    
				[ 'page' => $pageNumber,   
  				'lottery_type' => 'SSQ', 
  				'sort_obj' => 'process', 
  				'sort' => 'desc',
  				'chg_type' => '0',
  				#'issue' => '56675',
  				'amount' => 'all', 
  				'is_not_full' => '1'
				]  ); 
	
	OutputLog( "$url error:  $response->status_line")   unless $response->is_success;  
	OutputLog( "Weird content type at $url --  $response->content_type" )   unless $response->content_type eq 'text/html';  

	my @link = fetchLink( $response->content );
	storeLink2Queue( @link );
}
#��ȡδ��Ա��ҳ
sub getHomeFlag1{
	OutputLog( "program on getHomeFlag1" );
	my ($pageNumber) = @_;
	my $response = $browser->post( $url,    
				[ 'page' => $pageNumber,   
  				'lottery_type' => 'SSQ', 
  				'sort_obj' => 'process', 
  				'sort' => 'desc',
  				'chg_type' => '0',
  				#'issue' => '56675',
  				'amount' => 'all', 
  				'is_not_full' => '1'
				]  ); 

	OutputLog( "$url error:  $response->status_line")   unless $response->is_success;  
	OutputLog( "Weird content type at $url --  $response->content_type" )   unless $response->content_type eq 'text/html';  
	return $response->content;
}

