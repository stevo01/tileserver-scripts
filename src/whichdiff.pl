#!/usr/bin/perl

use LWP::UserAgent;
use strict;

my $tofind = $ARGV[0];

if (!$tofind)
{
    print "usage: perl whichdiff.pl nodeid\n";
    print "finds minutely status file to use if your max node is the given id\n";
    exit;
}

my $ua = LWP::UserAgent->new;

my $topdirs = [];
my $checked = {};
my $basedir = "http://planet.openstreetmap.org/replication/minute/";

my $root = $ua->get($basedir);

die unless($root->is_success);

my $cnt = $root->content;

while($cnt =~ m!<a href="(\d+)/">(\d+)/</a>!gm)
{
    push(@$topdirs, $1);
    printf("topdir $1\n");
}

my $subdirs = [];
while(my $td = pop(@$topdirs))
{
    printf("get $basedir/$td\n");
    my $subdir = $ua->get("$basedir/$td/");
    die unless($subdir->is_success);
    $cnt = $subdir->content;
    while($cnt =~ m!<a href="(\d+)/">(\d+)/</a>!gm)
    {
        push(@$subdirs, $td."/".$1);
    }
}

my @a = sort(@$subdirs);

while(my $sd = pop(@a))
{
    printf("pop $sd\n");
    my $files = [];
    my $index = $ua->get("$basedir/$sd/");
    die unless($index->is_success);
    $cnt = $index->content;

    while($cnt =~ m!<a href="(\d+\.osc\.gz)">(\d+)\.osc\.gz</a>!gm)
    {
        unshift(@$files, $sd."/".$1);
    }
    die unless (scalar @$files);

    my $first = 0;
    my $firstfirstnode = firstnode($files->[$first]);
    next if ($firstfirstnode == 0 || $firstfirstnode > $tofind);
    my $last = scalar(@$files) -1;
    my $lastfirstnode = firstnode($files->[$last]);

    found($files->[$last]) if ($lastfirstnode <= $tofind && $lastfirstnode > 0);

    while(1)
    {
        my $mid = ($first + $last) / 2;
        my $midfirstnode = firstnode($files->[$mid]);
        if ($midfirstnode > $tofind)
        {
            $last = $mid;
            $lastfirstnode = $midfirstnode;
        }
        elsif ($midfirstnode < $tofind)
        {
            if ($checked->{$files->[$mid+1]})
            {
                found($files->[$mid]);
            }
            $first = $mid;
            $firstfirstnode = $midfirstnode;
        }
        elsif ($midfirstnode == $tofind)
        {
            found($files->[$mid]);
        }
    }
}

sub firstnode
{
    my ($file) = shift;
    $checked->{$file} = 1;
    printf("check $basedir/$file\n");
    open (I, "wget -qO- $basedir/$file | zcat |") or die;
    my $cr = 0;
    my $id = 0;
    while(<I>)
    {
        if (m!<create>!)
        {
            $cr=1;
        } 
        elsif ($cr) 
        {
            if (m!</create>!)
            {
                $cr=0;
            }
            elsif (m!<node id="(\d+)"!)
            {
                $id = $1;
                last;
            }
        }
    }
    print "firstnode $file = $id\n";
    return $id;
}

sub found
{
    my ($file) = shift;
    print "node $tofind found in file $file\n";
    $file =~ /(.*)\/(\d+)\.osc\.gz/ or die;
    $file = sprintf("%s/%03d.state.txt", $1, $2-10);
    print "therefore, use status file $file:";
    my $r = $ua->get($basedir.$file);
    print($r->content);
    exit;
}

