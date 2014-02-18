#!/usr/bin/perl
## Copyright (C) 2013 Carnë Draug <carandraug+dev@gmail.com>
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

## Convert protein sequence using the 3 letter amino acid code, into
## IUPAC code. Reads sequence from STDIN.
##
## Examples:
##
##  bioinformatics/short2shorter.pl <<< "MetAlaGluTer"
##  bioinformatics/short2shorter.pl <<< echo file_with_sequence_in_3_letter
##
## will print:
##
##  MAE*

use 5.010;
use strict;
use warnings;
use Bio::PrimarySeq;
use Bio::SeqUtils;

## we will print the string only, but we a protein Bio::Seq to use seq3in
my $seq = Bio::PrimarySeq->new(
  -alphabet => "protein",
);

say Bio::SeqUtils->seq3in($seq, $_)->seq() while (<STDIN>);

