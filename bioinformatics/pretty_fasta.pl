#!/usr/bin/perl
## Copyright (C) 2011 Carnë Draug <carandraug+dev@gmail.com>
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

use 5.010;
use strict;                     # Enforce some good programming rules
use warnings;                   # Replacement for the -w flag, but lexically scoped
use Getopt::Long;               # Parse program arguments
use File::Spec;                 # Perform operation on file names
use Bio::SeqIO;                 # Handler for SeqIO Formats
use POSIX qw/ceil/;             # round up function

## XXX as of 2013/02/05 I have incorporated the block method in bioperl-live
## which would make writing this code much simpler. See
## See https://github.com/bioperl/bioperl-live/issues/51

=head1 NAME

pretty_fasta - makes a fasta sequence prettier and easier to read

=head1 SYNOPSIS

pretty_fasta [--block-length] [--line-length] FILES

=head1 DESCRIPTION

pretty_fasta reads in sequence files of any type supported by BioPerl and saves
them in fasta format with some aesthetic changes with the intention of making
the fasta sequence easier to read and count.

Output sequences are saved on the same directory as input files, in files with
same named and the `pretty_' prefix.

=head1 OPTIONS

=over

=item B<--block-length>

Specifies the number of characters on each block of the sequence. Each line can
have multiple blocks separated by spaces. Defaults to 10.
=cut
my $block_size    = 10;
=item B<--line-length>

Specifies the number of blocks on each line. Defaults to 10.
=cut
my $blocks_per_line  = 10;
=back
=cut

GetOptions(
            'block-length=i'  => \$block_size,
            'line-length=i'   => \$blocks_per_line,
          ) or die "Error processing options";
## It is necessary to check success of GetOptions since:
## ''GetOptions returns true to indicate success. It returns false when the function
## detected one or more errors during option parsing. These errors are signaled
## using warn() and can be trapped with $SIG{__WARN__}''
##
## This means that die() inside the subs that check the options are trapped and transformed
## into warn(). TODO there's probably a way to make warn() back into die() for this part only
## Go see $SIG{__WARN__}

## separator between blocks (should be a space)
my $separator   = ' ';

## warn if total line length will be >120 (not recommended)
warn ("warning: total line length will be loner than 120 characters") if ($block_size * $blocks_per_line + length ($separator) * ($blocks_per_line - 1) > 120);

## Arguments are sequence files (can be any format)
foreach my $path (@ARGV) {
  my $in    = Bio::SeqIO->new(
                              -file => $path,
                              );
  my ($dirpath, $filename) = File::Spec->splitdir($path);
  my $savepath             = File::Spec->catfile($dirpath, 'pretty_'.$filename);
  open (SEQ, ">", $savepath) or die "Could not open file $savepath for writing: $!";
  ## Read sequences from the file
  while (my $seq = $in->next_seq) {
    my $name    = $seq->display_name;
    my $desc    = $seq->desc;
    my $length  = $seq->length;
    say SEQ ">$name $desc";           # Don't forget the '>' before the name
    if ($length <= $block_size) {
      say SEQ $seq->seq;
      next;
    }

    my $blocks_on_line  = 0;  # current number of blocks on current line
    my $start           = 1;  # start position on the sequence for the block
    my $end             = 0;  # end position on the sequence for the block
    my $final_block     = ceil ($length/$block_size);
    for my $block (1 .. $final_block) {
      $end = $start + $block_size - 1;
      $end = $length if ($end > $length);

      print SEQ $seq->subseq($start, $end);
      $blocks_on_line++;
      $start += $block_size;

      if ($block == $final_block) {
        print SEQ "\n";
        last;
      } elsif ($blocks_on_line >= $blocks_per_line) {
        print SEQ "\n";
        $blocks_on_line = 0;
      } else {
        print SEQ $separator;
      }
    }
  }
}
