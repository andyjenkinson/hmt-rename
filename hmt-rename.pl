#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use WebService::TVDB;
require File::HomeDir;
require File::Spec;
use File::Copy;
use Getopt::Long;

my $script = basename($0);
my $HMT = '/usr/local/bin/hmt-linux';
my $SYNTAX = "$script [-n] <filename>\n\n\t-n\tDon't rename files, just print the changes\n";
my $VERBOSE = 0;

my ($no,$title);

GetOptions (  "series=s"   => \$title,      # string
              "verbose"    => \$VERBOSE,
              "n"          => \$no);   # flag

my @files = @ARGV;
scalar @files || die $SYNTAX;

my $keyfile = File::Spec->catfile(File::HomeDir->my_home, '.tvdb');
-f $keyfile || die "No TVDB API key file exists: $keyfile\n";

my $tvdb = WebService::TVDB->new(language => 'English', max_retries => 3);
my $langob = $WebService::TVDB::Languages::languages->{$tvdb->language} || die "Unknown language: $tvdb->language. Your TVDB API may not be installed correctly.\n";

my $series_cache = {};

for my $fn (@files) {
  process_file($fn);
}

sub process_file {
  my ($fn) = @_;

(undef, my $filedir, undef) = File::Spec->splitpath($fn);
my $filebase = $fn;
$filebase =~ s/(hmt|nts|thm|ts)$//;
$filebase =~ s/\.$//;

my $tabs = `$HMT -p "$filebase.hmt"` || die "Unable to run $HMT\n";
my @fields = split /\t/, $tabs;
# Title, Synopsis, HD/SD, LCN, Channel Name, Start time, End time, Flags, Guidance, Number of bookmarks, Scheduled start, Scheduled duration, Genre code

my $eptitle;

if (!$title) {
  $title = $fields[0];
}
else {
   $eptitle = $fields[0];
}
my $synopsis  = $fields[1];
my $guidance = $fields[8];

my $desc = $synopsis;
# Clean tags from end of synopsis
$desc =~ s/\[HD\]//;
$desc =~ s/\[S\]//;
$desc =~ s/\s+$//;
if ($guidance) {
  $desc =~ s/ $guidance//;
}
my ($ep, $eptotal, ) = $desc =~ m/^(\d+)\/(\d+)\.\s+/;

if ($ep && $eptotal) {
  $desc =~ s/^\d+\/\d+\.\s+//;
}

my ($tmp) = $desc =~ m/^([^:]+)\:\s+\w+/;
if ($tmp) {
  $eptitle = $tmp;
  $desc =~ s/^$eptitle\:\s+//;
}

if ($VERBOSE) {
  my $s = "Using series '$title' episode";
  if ($ep) {
    $s .= " $ep";
    if ($eptotal) {
      $s .= " of $eptotal";
    }
  }
  $s .= " '$eptitle'\n";
  print $s;
}

my $lang = $langob->{name};
my $langabb = $langob->{abbreviation};

my $series = $series_cache->{$title};
if (!$series) {

  $VERBOSE && print "Searching TVDB ($lang/$langabb)\n";

  my $series_list = $tvdb->search($title);
  $series = $series_list->[0];
  if (!$series) {
    $series_cache->{$title} = $series = 'FAIL';
  }
  else {
    $VERBOSE && print "Series ID: $series->{id}\n";

    # Get all the data
    $series->fetch();
    $series_cache->{$title} = $series;
  }
}

if ($series eq 'FAIL') { 
  print "Unable to find series with name \"$title\"\n";
  return 1;
}

my @episodes = grep { $_->{EpisodeNumber} } @{ $series->episodes() || [] };

my $episode;
for my $tmp_episode (@episodes) {

  my $eptA = transform_eptitle($eptitle);
  my $eptB = transform_eptitle($tmp_episode->{EpisodeName});

  if ( ($ep && $tmp_episode->{EpisodeNumber} == $ep) || ($eptA && $eptB && $eptA eq $eptB) ) {
    $episode = $tmp_episode;
    last;
  }
}

  if ($episode) {
    my $newbase;
    if (!$episode->{EpisodeName}) {
      $VERBOSE && printf "Found episode %d (%d)\n", $episode->{EpisodeNumber}, $episode->{id};
      $newbase = $filedir . sprintf '%s.S%02dE%02d', $title, $episode->{SeasonNumber}, $episode->{EpisodeNumber};
    } else {
      $VERBOSE && printf "Found episode %d - %s (%d)\n", $episode->{EpisodeNumber}, $episode->{EpisodeName}, $episode->{id};
      $newbase = $filedir . sprintf '%s.S%02dE%02d.%s', $title, $episode->{SeasonNumber}, $episode->{EpisodeNumber}, $episode->{EpisodeName};
    }

    print "$filebase will be renamed: $newbase\n";
    for my $ext (qw(hmt thm nts ts)) {
      my $oldfile = "$filebase.$ext";
      my $newfile = "$newbase.$ext";
      if (!$no) {
        move($oldfile, $newfile) || die "Unable to rename $oldfile to $newfile\n";
      }
    }
  }
  else {
    print "$filebase will not be renamed\n";
  }

} # end process_file

sub transform_eptitle {
  my $eptitle = shift;

  $eptitle || return q[];

  $eptitle = lc $eptitle;
  $eptitle =~ s/\s+and\s+/ \& /g;
  $eptitle =~ s/\s+the\s+//g;
  $eptitle =~ s/^the\s+//g;
  $eptitle =~ s/[^a-z0-9\s\&]//g;
  $eptitle =~ s/\s//g;

#  $VERBOSE && print "Comparing title: $eptitle\n";
  return $eptitle;
}
