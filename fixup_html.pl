#!/usr/bin/perl
use strict;
use warnings;

opendir( my $dh, './book/') || die;
my @html = grep { /\.html$/ && -f "./book/$_" } readdir($dh);
closedir $dh;

my $SCRIPT = qq~
<script type="text/javascript"><!--
google_ad_client = "pub-3377830205531449";
/* large horizontal - rewrite */
google_ad_slot = "4928503505";
google_ad_width = 728;
google_ad_height = 90;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>

<br />
~;

foreach my $h ( @html ) {
    chomp $h;
    open ( my $fh, "<./book/$h" ) || die $!;
    my @contents = <$fh>;
    close $fh;

    my $page = join '', @contents;
    $page =~ s/<BODY >/<BODY >\n$SCRIPT/;
    $page =~ s~</ADDRESS>~</ADDRESS>\n$SCRIPT~;

    open ( my $out, ">./book/$h" )  || die $!;
    print $out $page;
    close( $out );

}
