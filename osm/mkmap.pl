#!/usr/bin/perl

# generated from http://openstreetmap.gryph.de/bigmap.cgi/
# permalink for this map: http://openstreetmap.gryph.de/bigmap.cgi?xmin=46884&xmax=46899&ymin=30380&ymax=30391&zoom=16&scale=256&baseurl=http%3A%2F%2Ftile.openstreetmap.org%2F!z%2F!x%2F!y.png
#
use strict;
use LWP;
use GD;

my $img = GD::Image->new(4096, 3072, 1);
my $white = $img->colorAllocate(248,248,248);
$img->filledRectangle(0,0,4096,3072,$white);
my $ua = LWP::UserAgent->new();
$ua->env_proxy;
for (my $x=0;$x<16;$x++)
{
    for (my $y=0;$y<12;$y++)
    {
        my $xx = $x + 46884;
        my $yy = $y + 30380;
        foreach my $base(split(/\|/, "http://tile.openstreetmap.org/16/!x/!y.png"))
	{
		my $url = $base;
                $url =~ s/!x/$xx/g;
                $url =~ s/!y/$yy/g;
		print STDERR "$url... ";
		my $resp = $ua->get($url);
		print STDERR $resp->status_line;
		print STDERR "\n";
		next unless $resp->is_success;
		my $tile = GD::Image->new($resp->content);
		next if ($tile->width == 1);
		if ($base =~ /seamark/) {
		my $black=$tile->colorClosest(0,0,0);
		$tile->transparent($black);
		}
		$img->copy($tile, $x*256,$y*256,0,0,256,256);
	}
    }
}
binmode STDOUT;
print $img->png();
