#!/usr/bin/perl -w

use strict;
use File::Basename;
use Getopt::Long;

my @filetypes = qw(.avi .mp4 .mkv .mov .m4v);

my ($dir, $outdir, $delete_orig, $encoder, $help);

GetOptions("h|help" => \$help,
            "i=s"   => \$dir,
            "o=s"   => \$outdir,
            "e=s"   => \$encoder,
            "d"     => \$delete_orig
) or ($help = 1);

$encoder = "H.265 NVENC 1080p" unless $encoder;

if ($help or !$dir) { print qq{

usage: $0 -i <indir>

Reprocesses all video files in directory using HandBrakeCLI

Options:
  -i : String: In directory (required)
  -o : String: Out directory (optional).  Default will be same as -i and output files will be placed where input files were found.
  -e : Quoted String: HandBrake preset encoder option (optional).  Default: "H.265 NVENC 1080p".  Note, this is for NVIDIA GPU acceleration.
  -d : Boolean: Delete original file after encoding (optional).  Default: 0
};
exit;
} 

#my ($dir, $ooutdir, $delete_orig, $encoder);
#my $dir = $opts{i};
#$dir = "." unless $dir;
#my $outdir = $opts{o};
#my $delete_orig = $opts{d} || 0;
#my $encoder = $opts{e} || "H.265 NVENC 1080p";
#my @filetypes = qw(.avi .mp4 .mkv .mov .m4v);

process_dir($dir);


sub process_dir {
  my $dir = shift;
  opendir (DIR, $dir) || die "Can't open directory $dir for reading: $!";
  my @dirs;
  while (my $item = readdir DIR) {
    next if $item =~ /^\.\.?$/;
    if (-d "$dir/$item") { push @dirs, "$dir/$item";}
    elsif (-r "$dir/$item") {
      process_video("$dir/$item");
    }
  }
  foreach my $item (@dirs) {process_dir($item)};
}

sub process_video {
  my $file = shift;
  foreach my $item (@filetypes) {
    if ($file =~ /$item$/) { 
      my $ofile = $file;
      $ofile =~ s/$item$/\.h265.mkv/;
      $ofile =~ s/\.\w264//;
      $ofile =~ s/\.\.+/\./g;
      if ($outdir) {
        $ofile = basename($ofile);
        $ofile = $outdir."/".$ofile;
      }
      my $cmd = "HandBrakeCLI -i \"$file\" -o \"$ofile\" --preset=\"$encoder\"";
      print "Processing: ".$cmd, "\n";
      system ($cmd);
      if ($delete_orig) {
        print "Deleting original file: $file\n";
        system ("rm \"$file\"");
      }
    }
  }
} 
