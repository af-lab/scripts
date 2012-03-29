#!/usr/bin/perl
## Copyright (C) 2012 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

## Thanks to Altreus, anno, uri and tybalt89 from freenode's #perl

my $positive_aa = "gs";           # amino acids that count
my $min_number  = 7;              # minimum number of $positive_aa to count
my $window_size = 10;             # size of the window to look for $min_number of $positive_aa
my $total_freq  = 6.9;            # frequency of $positive_aa. The average number of aa to find ONE of the aa in $positive_aa
my $brute_force = 0;              # use brute force (not very efficient at all). You should NOT need to do this

## note that this script might fail or silently not work properly when $window_size
## is large relatively to $total_freq. You should NOT encounter such situation. If you
## think this an issue, turn $brute_force into 1. The brute_force method will ignore
## the vale of $total_freq

## for $total_freq check McCaldon, Peter; Argos, Patrick (1988). Oligopeptide biases in
## protein sequences and their use in predicting protein coding regions in nucleotide
## sequences. Proteins: structure, function and genetics 4 (2), 99--122.
##
## for "gs", since g = 7.2 and s = 6.9, $total_freq = 6.9 (the smallest value)

################################################################################
## code from this point on. Do NOT edit beyond this
################################################################################
use 5.010;                      # Use Perl 5.10
use warnings;                   # Replacement for the -w flag, but lexically scoped
use strict;                     # Enforce some good programming rules
use Bio::SeqIO;                 # Handler for SeqIO Formats

## we are using tr/// for the match later. Since it doesn't make case insensitive
## we need to make a new string that has the characters both upper and lower case
$positive_aa  = lc ($positive_aa) . uc ($positive_aa);

foreach my $file (@ARGV) {
  my $seqio = Bio::SeqIO->new(
                              -file => $file
                              );
  while (my $seq = $seqio->next_seq){
    my @subseqs;
    if ($brute_force) {
      @subseqs = brute_force ($seq->seq);
    } else {
      @subseqs = educated_guess ($seq->seq);
    }
    say "Found on `$file' in `". $seq->desc ."' the sequence $_" foreach (@subseqs);
  }
}

## very brute-force approach. Pretty much slides through the sequence and looks
## for a match in every single subsequence of size $window_size
## call to brute_force is "brute_force ($seq)"
sub brute_force {
  return grep eval "tr/$positive_aa// >= $min_number", $_[0] =~ /(?=(.{$window_size}))/g;
}

## considering the frequency of the aa, count the number of occurences on a substring
## just enough to not have the $min_number of aa. Then split in half and do it again
## only do a brute_force search by sliding window if true after this
sub educated_guess {
  ## this is the average number of aa that one should need check to find the
  ## $min_number -1. This mean that if there's no hit on the sequence, in average
  ## we should never guess positive to look deeper into the string
  my $sub_size = int($total_freq * ($min_number -1));

  my ($start, $hits) = (0, 0);
  my @hits_seq;
  while ($start + $window_size < length $_[0]) {
    my $substr = substr ($_[0], $start, $sub_size);
    $hits = count_hits ($substr);
    if ($hits > $min_number) {
      ## we region around the middle of the string goes in both halves since 
      ## it is possible that the hit is there
      my $first_half    = substr ($substr, 0, (length $substr)/2 + ($window_size/2));
      my $second_half   = substr ($substr, (length $substr)/2 - ($window_size/2));

      for ($first_half, $second_half) {
        push @hits_seq, brute_force ($_) if count_hits ($_) > $min_number;
      }
    }
    ## we need to go back $window_size +1 characters because it's possible that
    ## there's a match there. If we are interested in strings of size 10, the
    ## 9 of the previous sequence plus the first of the new could be a hit
    $start += $sub_size - $window_size + 1;
  }
  return @hits_seq;
}

sub count_hits {
  my $hits = eval "\$_[0] =~ tr/$positive_aa//";
  warn $@ if $@;
  return $hits;
}

#$_ = 'gdsdfgsgsgsgsdffsgsgsdffgsdgsgs';
#while ( /[gs]/g ) {
#  if ( substr($_, $-[0], 10) =~ tr/[gs]// >= 7 ) {
#    push @offsets, $-[0];
#  }
#}
