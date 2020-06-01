#!/usr/bin/perl -w

$w = shift || 240;
$h = shift || 320;
$pixels = $w * $h;

open OUT, "|pnmtopng" or die "Can't pipe pnmtopng: $!\n";

printf OUT "P6%d %d\n255\n", $w, $h;

while ((read STDIN, $raw, 4) and $pixels--) {
   $short = unpack('S', $raw);
   print OUT pack("C3",
      ($short & 0xf800) >> 8,
      ($short & 0x7e0) >> 3,
      ($short & 0x1f) << 3);
}

close OUT;
