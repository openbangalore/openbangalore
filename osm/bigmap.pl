#!/usr/bin/perl

use CGI;
use URI::Escape;
use strict;
use Math::Trig;

my $query = CGI->new();

my $xmin = int($query->param("xmin"));
my $xmax = int($query->param("xmax"));
my $ymin = int($query->param("ymin"));
my $ymax = int($query->param("ymax"));
my $zoom = int($query->param("zoom"));
my $baseurl = $query->param("baseurl");
my $scale = $query->param("scale") || 256;
my $tileurl = $query->param("tileurl");

if ($tileurl =~ m!^(.*?)/(\d+)/(\d+)/(\d+)\.png!)
{
   $xmin = $3-1; $xmax = $3+1;
   $ymin = $4-1; $ymax = $4+1;
   $baseurl = $1;
   $zoom = $2;
   $baseurl =~ s/\/(relief|trails)//g;
}

if ($ENV{"QUERY_STRING"} eq "")
{
   printf("Location: bigmap.html\n\n");
   exit 1;
}

$baseurl = "http://tah.openstreetmap.org/Tiles/tile/!z/!x/!y.png" unless defined $baseurl;

# check for perl script before we do any headers
if ($query->param("perl"))
{
    makeperl();
    exit 1;
}

print <<EOF;
Content-type: text/html

<html><head><title>BigMap</title></head><body>
EOF

if ($query->param("form") or ($xmin<0 || $ymin<0 || $zoom<1 || $zoom>18 || $xmax>2**$zoom || $ymax>2**$zoom || $ymin>$ymax || $xmin>$xmax))
{
print <<EOF;
<h1>bigmap</h1>

<strong>Arranging OpenStreetMap Map Tiles</strong>
<p>
The bigmap service creates maps from the same tiles used for the well-known "slippy maps"
(e.g. <a href="http://www.informationfreeway.org/">informationfreeway.org</a>). However,
it does so without Javascript or CSS. This means the resulting maps are less suitable for
online browsing, but better for printing. 

<p>

Please select your initial settings:
<br>
(or <font color="red"><b>new!</b></font> use the <a href="bigmap.html">OpenLayers interface</a> to select an area)

<form method="get">
<table>

<tr><td colspan=4><hr><br>map parameters:</td></tr>
<tr>
<td>Zoom Level</td>
<td>&nbsp;</td>
<td><select name="zoom">
EOF

for (my $i=5; $i<19; $i++)
{
    print "<option value='$i' ";
    print " selected" if ($zoom==$i);
    print ">$i";
    print " (mapnik only)" if ($i==18);
    print "</option>\n";
}
print <<EOF;
</select>
</td>
</tr>

<tr>
<td>X Range</td>
<td>&nbsp;</td>
<td><input type="text" name="xmin" size="8" value="$xmin" /> - <input type="text" name="xmax" size="8" value="$xmax" />
</td>
</tr>

<tr>
<td>Y Range</td>
<td>&nbsp;</td>
<td><input type="text" name="ymin" size="8" value="$ymin" /> - <input type="text" name="ymax" size="8" value="$ymax" />
</td>
</tr>

<tr><td /><td /><td><em>all ranges in tile numbers please, not coordinates!</em></td></tr>

<tr>
<td>Tile Source</td>
<td>&nbsp;</td>
<td><select name="baseurl">
EOF

# note first 3 digits are cut off later, just for ordering
my %layers = (
    '07 cyclemap' => 'http://tile.opencyclemap.org/cycle/!z/!x/!y.png',
    '06 mapnik' => 'http://tile.openstreetmap.org/!z/!x/!y.png',
    '08 öpnv' => 'http://tile.öpnvkarte.de/tilegen/!z/!x/!y.png',
    '09 wanderreitkarte' => 'http://base.wanderreitkarte.de/base/!z/!x/!y.png|http://www.wanderreitkarte.de/hills/!z/!x/!y.png|http://topo.wanderreitkarte.de/topo/!z/!x/!y.png',
    '10 hikebikemap' => 'http://toolserver.org/tiles/hikebike/!z/!x/!y.png|http://toolserver.org/~cmarqu/hill/!z/!x/!y.png',
    '11 wanderreitkarte+srtm' => 'http://base.wanderreitkarte.de/base/!z/!x/!y.png|http://toolserver.org/~cmarqu/hill/!z/!x/!y.png|http://toolserver.org/~cmarqu/opentiles.com/cmarqu/tiles_contours_8/!z/!x/!y.png|http://topo.wanderreitkarte.de/topo/!z/!x/!y.png',
    '14 license change' => 'http://tile.openstreetmap.org/mapnik/!z/!x/!y.png|http://osm.informatik.uni-leipzig.de/osm_tiles2/!z/!x/!y.png',
    '15 openseamap' => 'http://tile.openstreetmap.org/mapnik/!z/!x/!y.png|http://tiles.openseamap.org/seamark/!z/!x/!y.png',
    '16 mapnik+seamap weather' => 'http://tile.openstreetmap.org/mapnik/!z/!x/!y.png|http://www.openportguide.org/tiles/actual/wind_vector/5/!z/!x/!y.png|http://www.openportguide.org/tiles/actual/surface_pressure/5/!z/!x/!y.png',
    '17 relief' => 'http://www.maps-for-free.com/layer/relief/z!z/row!y/!z_!x-!y.jpg');
    
foreach my $k (sort keys %layers)
{
    printf("<option value='%s'%s>%s</option>\n", 
        $layers{$k}, 
        ($baseurl eq $layers{$k}) ? " selected" : "",
        substr($k, 3));
}

print <<EOF;
</select>
</td>
</tr>
<tr><td colspan=4><hr><br>alternatively, paste a tile URL to start:</td></tr>
<tr>
<td>Tile URL</td>
<td>&nbsp;</td>
<td><input name="tileurl">
</td>
</tr>

<tr>
<td colspan="3" align="right">
<input type="submit" name="Submit" />
</td>
</tr>
<tr><td colspan=4><hr></td></tr>
</table>
</form>
<strong>Usage:</strong>
<p>
Once you have entered coordinates above, a map will be shown consisting of the tiles
requested. Note that the bigmap server <b>never</b> loads the tiles for you, instead
it instructs your browser to load the tiles. So if you see nothing, or see garbage,
then it is likely the tile server's fault, or you have entered invalid data (invalid
zoom levels for example).

<p>

The map you see will be overlaid with a small control box that allows you to make 
corrections, e.g. enlarging, reducing, or moving the map, and zooming in or out.

<p>

Once you are satisfied with what you see, you can either hide the control box and
print the page from your browser, or you can click the "Perl" link which will
download a very small Perl program onto your computer that, when executed, will
download all the tiles you see and compose one large PNG file from them. (This
Perl script can be saved and run at a later time to capture any updates that
have taken place in the mean time - no need to go back to the bigmap service.)

<pre>
Perl Script Usage:
perl mkmap.pl > mymap.png
</pre>

<p>
<strong>The map control box:</strong>
<p>
<img src="bigmap.png">
<p>

<strong>Adding further tilesets:</strong>
<p>
This form has only a limited number of tilesets in the dropdown box above, but
you can theoretically send anything to the script - it doesn't check it.
<p>
<a href="bigmap.txt">Download bigmap.cgi source code.</a> bigmap.cgi is written
by Frederik Ramm and released into the <b>public domain</b>.

EOF
}
else
{
    # these 2 nested for loops do the actual map.
    for (my $y=$ymin;$y<=$ymax;$y++)
    {
        print "<nobr>";
        for (my $x=$xmin; $x<=$xmax; $x++)
        {
            if ($baseurl =~ /\|/)
            {
               my @layers = split(/\|/, $baseurl);
               my $xp = $scale * ($x-$xmin);
               my $yp = $scale * ($y-$ymin);
               my $bg = shift @layers;
               $bg =~ s/!z/$zoom/g;
               $bg =~ s/!x/$x/g;
               $bg =~ s/!y/$y/g;
               print "<div style=\"position:absolute; left:$xp; top:$yp; width: $scale; height: $scale\">\n";
               print "<img src=\"$bg\" width=\"$scale\" height=\"$scale\" onclick=\"getElementById('control').style.display='block';\"></div>";
               while(my $ovl = shift @layers)
               {
                  $ovl =~ s/!z/$zoom/g;
                  $ovl =~ s/!x/$x/g;
                  $ovl =~ s/!y/$y/g;
                  print "<div style=\"position:absolute; left:$xp; top:$yp; width: $scale; height: $scale\">\n";
                  print "<img src=\"$ovl\" width=\"$scale\" height=\"$scale\" onclick=\"getElementById('control').style.display='block';\"></div>";
               }
            }
            else
            {
               my $bg = $baseurl;
               $bg =~ s/!z/$zoom/g;
               $bg =~ s/!x/$x/g;
               $bg =~ s/!y/$y/g;
               print "<img src=\"$bg\" width=\"$scale\" height=\"$scale\" onclick=\"getElementById('control').style.display='block';\">";
            }
        }
        print "</nobr><br>\n";
    }

    # everything that follows is just for the control box!
    print '<div id="control" style="align:center;position:fixed;top:50px;margin-left:50px;margin-right:50px;padding:10px;background:#ffffff;opacity:0.8;border:solid 1px;border-color:green;">';
    my $widtiles = $xmax-$xmin+1;
    my $heitiles = $ymax-$ymin+1;
    my $widpix = $widtiles*256;
    my $heipix = $heitiles*256;
    my $asp="1:1";
    if ($widpix>$heipix)
    {
        $asp = sprintf("%.1f:1", $widpix/$heipix);
    }
    elsif($widpix<$heipix)
    {
        $asp = sprintf("1:%.1f", $heipix/$widpix);
    }

    printf "Map is %dx%d tiles (%dx%d px) at zoom %d, aspect %s<br>",
        $widtiles,$heitiles,$widpix,$heipix,$zoom,$asp;
    my ($d,$o1,$a1,$d) = Project($xmin, $ymin, $zoom);
    my ($a2,$d,$d,$o2) = Project($xmax, $ymax, $zoom);
    if ($zoom>7)
    {
    printf "Bbox is %10.6f,%10.6f,%10.6f,%10.6f (l,b,r,t)<br>",
        $o1, $a2, $o2, $a1;
    }
    else
    {
    printf "Bbox is %7.2f,%7.2f,%7.2f,%7.2f (l,b,r,t)<br>",
        $o1, $a2, $o2, $a1;
    }
    print '<table cellspacing="0" cellpadding="2"><tr>';
    print td("tl", "right", $xmin-1, $xmax, $ymin-1, $ymax, $zoom);
    print td("top", "center", $xmin, $xmax, $ymin-1, $ymax, $zoom);
    print td("tr", "left", $xmin, $xmax+1, $ymin-1, $ymax, $zoom);
    print "<td>&nbsp;</td>";
    print td("ul", "right", $xmin-1, $xmax-1, $ymin-1, $ymax-1, $zoom);
    print td("up", "center", $xmin, $xmax, $ymin-1, $ymax-1, $zoom);
    print td("ur", "left", $xmin+1, $xmax+1, $ymin-1, $ymax-1, $zoom);
    print "<td>&nbsp;</td>";
    print td("tl", "right", $xmin+1, $xmax, $ymin+1, $ymax, $zoom);
    print td("top", "center", $xmin, $xmax, $ymin+1, $ymax, $zoom);
    print td("tr", "left", $xmin, $xmax-1, $ymin+1, $ymax, $zoom);
    print "</tr><tr>";
    print td("left", "right", $xmin-1, $xmax, $ymin, $ymax, $zoom);
    print "<td align='center' bgcolor='#aaaaaa'><b>EXPAND</b></td>";
    print td("right", "left", $xmin, $xmax+1, $ymin, $ymax, $zoom);
    print "<td>&nbsp;</td>";
    print td("left", "right", $xmin-1, $xmax-1, $ymin, $ymax, $zoom);
    print "<td align='center' bgcolor='#aaaaaa'><b>SHIFT</b></td>";
    print td("right", "left", $xmin+1, $xmax+1, $ymin, $ymax, $zoom);
    print "<td>&nbsp;</td>";
    print td("left", "right", $xmin+1, $xmax, $ymin, $ymax, $zoom);
    print "<td align='center' bgcolor='#aaaaaa'><b>SHRINK</b></td>";
    print td("right", "left", $xmin, $xmax-1, $ymin, $ymax, $zoom);
    print "</tr><tr>";
    print td("bl", "right", $xmin-1, $xmax, $ymin, $ymax+1, $zoom);
    print td("bottom", "center", $xmin, $xmax, $ymin, $ymax+1, $zoom);
    print td("br", "left", $xmin, $xmax+1, $ymin, $ymax+1, $zoom);
    print "<td>&nbsp;</td>";
    print td("dl", "right", $xmin-1, $xmax-1, $ymin+1, $ymax+1, $zoom);
    print td("down", "center", $xmin, $xmax, $ymin+1, $ymax+1, $zoom);
    print td("dr", "left", $xmin+1, $xmax+1, $ymin+1, $ymax+1, $zoom);
    print "<td>&nbsp;</td>";
    print td("bl", "right", $xmin+1, $xmax, $ymin, $ymax-1, $zoom);
    print td("bottom", "center", $xmin, $xmax, $ymin, $ymax-1, $zoom);
    print td("br", "left", $xmin, $xmax-1, $ymin, $ymax-1, $zoom);
    print "</tr><tr><td></td></tr>";
    print "<tr><td colspan='11'><table bgcolor='#aaaaaa' width='100%' border='0' cellpadding='0' cellspacing='0'><tr>";
    print "<td>&nbsp;</td>";
    print td("in/double size", "left", $xmin*2,$xmax*2+1,$ymin*2,$ymax*2+1,$zoom+1);
    print "<td>&nbsp;</td>";
    print td("in/keep size", "left", $xmin*2+($xmax-$xmin)/2,$xmax*2-($xmax-$xmin)/2,$ymin*2+($ymax-$ymin)/2,$ymax*2-($ymax-$ymin)/2,$zoom+1);
    print "<td>&nbsp;</td>";
    print "<td bgcolor='#aaaaaa'><b>ZOOM</b></td>";
    print "<td>&nbsp;</td>";
    print td("out/keep size", "left", $xmin/2-($xmax-$xmin)/4,$xmax/2+($xmax-$xmin)/4,$ymin/2-($ymax-$ymin)/4,$ymax/2+($ymax-$ymin)/4,$zoom-1);
    print "<td>&nbsp;</td>";
    print td("out/halve size", "left", $xmin/2,$xmax/2,$ymin/2,$ymax/2,$zoom-1);
    print "</tr></table></td></tr><tr><td></td></tr>";
    print "<tr><td colspan='11'><table bgcolor='#aaaaaa' width='100%' border='0' cellpadding='0' cellspacing='0'><tr>";
    print "<td>&nbsp;</td>";
    print td("Permalink", "left", $xmin,$xmax,$ymin,$ymax,$zoom);
    print "<td>&nbsp;</td>";
    my $fm = td("Form", "left", $xmin,$xmax,$ymin,$ymax,$zoom);
    $fm =~ s/\?/?form=1&/;
    print $fm;
    print "<td>&nbsp;</td>";
    my $pl = td("Perl", "left", $xmin,$xmax,$ymin,$ymax,$zoom);
    $pl =~ s/\?/?perl=1&/;
    print $pl;
    print "<td>&nbsp;</td>";
    print td("100", "left", $xmin,$xmax,$ymin,$ymax,$zoom,256);
    print "<td>/</td>";
    print td("50", "left", $xmin,$xmax,$ymin,$ymax,$zoom,128);
    print "<td>/</td>";
    print td("25%", "left", $xmin,$xmax,$ymin,$ymax,$zoom,64);
    print "<td>&nbsp;</td>";
    print "<td align='right'><a href=\"#\" onclick=\"getElementById('control').style.display='none';\">hide this (click map to show again)</a></td>";
    print "</tr></table></td></tr></table>";
    print "</div></div>";
}

print "</body></html>";

# helper to display a table cell with a parametrized link inside
sub td
{
    my ($what, $align, $xmi, $xma, $ymi, $yma, $zm, $scl) = @_;
    $scl=$scale unless defined ($scl);
    my $r = sprintf('<td bgcolor="#aaaaaa" align="%s"><a href="?xmin=%d&xmax=%d&ymin=%d&ymax=%d&zoom=%d&scale=%d&baseurl=%s">%s</a></td>',
        $align,
        $xmi, $xma,
        $ymi, $yma, 
        $zm, $scl, uri_escape($baseurl), $what);
    return $r;
}

# this generates the perl script that can be downloaded
sub makeperl
{
    my $widtiles = $xmax-$xmin+1;
    my $heitiles = $ymax-$ymin+1;
    my $widpix = $widtiles*256;
    my $heipix = $heitiles*256;
    my $formurl = $baseurl;
    $formurl .= "/$zoom/%d/%d.png";

    my $bu_with_zoom = $baseurl;
    $bu_with_zoom =~ s/!z/$zoom/g;

    my $script = sprintf(<<'EOF', "http://openstreetmap.gryph.de/bigmap.cgi?xmin=$xmin&xmax=$xmax&ymin=$ymin&ymax=$ymax&zoom=$zoom&scale=$scale&baseurl=" . uri_escape($baseurl), $widpix, $heipix, $widpix, $heipix, $widtiles, $heitiles, $xmin, $ymin, $bu_with_zoom);
#!/usr/bin/perl

# generated from http://openstreetmap.gryph.de/bigmap.cgi/
# permalink for this map: %s
#
use strict;
use LWP;
use GD;

my $img = GD::Image->new(%d, %d, 1);
my $white = $img->colorAllocate(248,248,248);
$img->filledRectangle(0,0,%d,%d,$white);
my $ua = LWP::UserAgent->new();
$ua->env_proxy;
for (my $x=0;$x<%d;$x++)
{
    for (my $y=0;$y<%d;$y++)
    {
        my $xx = $x + %d;
        my $yy = $y + %d;
        foreach my $base(split(/\|/, "%s"))
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
EOF

    print "Content-type: application/octet-stream\nContent-disposition: attachment; filename=\"mkmap.pl\"\n\n$script";
}

sub Project {
  my ($X,$Y, $Zoom) = @_;
  my $Unit = 1 / (2 ** $Zoom);
  my $relY1 = $Y * $Unit;
  my $relY2 = $relY1 + $Unit;
 
  # note: $LimitY = ProjectF(degrees(atan(sinh(pi)))) = log(sinh(pi)+cosh(pi)) = pi
  # note: degrees(atan(sinh(pi))) = 85.051128..
  #my $LimitY = ProjectF(85.0511);
 
  # so stay simple and more accurate
  my $LimitY = pi;
  my $RangeY = 2 * $LimitY;
  $relY1 = $LimitY - $RangeY * $relY1;
  $relY2 = $LimitY - $RangeY * $relY2;
  my $Lat1 = ProjectMercToLat($relY1);
  my $Lat2 = ProjectMercToLat($relY2);
  $Unit = 360 / (2 ** $Zoom);
  my $Long1 = -180 + $X * $Unit;
  return ($Lat2, $Long1, $Lat1, $Long1 + $Unit); # S,W,N,E
}
sub ProjectMercToLat($){
  my $MercY = shift;
  return rad2deg(atan(sinh($MercY)));
}
sub ProjectF
{
  my $Lat = shift;
  $Lat = deg2rad($Lat);
  my $Y = log(tan($Lat) + sec($Lat));
  return $Y;
}
