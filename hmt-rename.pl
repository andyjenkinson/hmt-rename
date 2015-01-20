#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use WebService::TVDB;
require File::HomeDir;
require File::Spec;
use File::Copy;

my $script = basename($0);
my $HMT = '/usr/local/bin/hmt-linux';
my $SYNTAX = "$script <filename>\n";

my $fn = shift;

$fn || die $SYNTAX;

(undef, my $filedir, undef) = File::Spec->splitpath($fn);
my $filebase = $fn;
$filebase =~ s/(hmt|nts|thm|ts)$//;
$filebase =~ s/\.$//;

my $tabs = `$HMT -p "$filebase.hmt"` || die "Unable to run $HMT\n";
my @fields = split /\t/, $tabs;
# Title, Synopsis, HD/SD, LCN, Channel Name, Start time, End time, Flags, Guidance, Number of bookmarks, Scheduled start, Scheduled duration, Genre code

my $title = $fields[0];
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

my ($eptitle) = $desc =~ m/^([^:]+)\:\s+\w+/;
if ($eptitle) {
  $desc =~ s/^$eptitle\:\s+//;
}

print "$title\n";
print "$eptitle\n";
print "$desc\n";
print "Episode $ep of $eptotal\n";

my $keyfile = File::Spec->catfile(File::HomeDir->my_home, '.tvdb');
-f $keyfile || die "No TVDB API key file exists: $keyfile\n";

my $tvdb = WebService::TVDB->new(language => 'English', max_retries => 3);
my $langob = $WebService::TVDB::Languages::languages->{$tvdb->language} || die "Unknown language: $tvdb->language. Your TVDB API may not be installed correctly.\n";

my $lang = $langob->{name};
my $langabb = $langob->{abbreviation};
print "Searching TVDB ($lang/$langabb)\n";

my $series_list = $tvdb->search($title);
my $series = $series_list->[0] || die "Unable to find series with name \"$title\"\n";

print "Series ID: $series->{id}\n";

# Get all the data
$series->fetch();

my @episodes = @{ $series->episodes() || [] };
@episodes = grep { $_->{EpisodeNumber} == $ep } @episodes;

for my $episode (@episodes) {
  print "Episode ID: $episode->{id}\n";
  print "Episode name: $episode->{EpisodeName}\n";

  if ($episode->{EpisodeNumber} == $ep && $episode->{EpisodeName} eq $eptitle) {
    # Exact match
    my $newbase = $filedir . sprintf '%s.S%02dE%02d.%s', $series->{SeriesName}, $episode->{SeasonNumber}, $episode->{EpisodeNumber}, $episode->{EpisodeName};
    print "$newbase\n";
    for my $ext (qw(hmt thm nts ts)) {
      my $oldfile = "$filebase.$ext";
      my $newfile = "$newbase.$ext";
      move($oldfile, $newfile) || die "Unable to rename $oldfile to $newfile\n";;
    }
    last;
  }
}

