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

use 5.010;                      # Use Perl 5.10
use strict;                     # Enforce some good programming rules
use warnings;                   # Replacement for the -w flag, but lexically scoped
use Bio::Seq;                   # Sequence object, with features
use Bio::SeqIO;                 # Handler for SeqIO formats
use Bio::Tools::Run::StandAloneBlastPlus;

## Search for histone genes in a sequence file (an entire chromosome perhaps)
## via blast, and report the coordinates of possible histone genes by order.
## Meant to find all histone genes of a cluster, and print a nice report with
## the cluster organization for comparison against others, and looking for
## orthologs.
##
## Example output:
##
##    Histone   Chromosome  Strand    Start      End      Distance
##    ------------------------------------------------------------
##    h2b      NC_006088.3    -       47928729  47929106      3714
##    h4       NC_006088.3    +       47932425  47932733      3319
##    h3       NC_006088.3    -       47933732  47934139       999
##    h3       NC_006088.3    +       47934973  47935380       834
##    h4       NC_006088.3    -       47936174  47936482       794
##    h2a      NC_006088.3    -       47943848  47944219      7366
##    h2b      NC_006088.3    +       47944568  47944945       349
##    h3       NC_006088.3    +       47946160  47946567      1215
##    h4       NC_006088.3    -       47953881  47954189      7314
##    h2a      NC_006088.3    -       47958623  47959009      4434
##    h2b      NC_006088.3    +       47959343  47959720       334
##
##
## XXX
##  * we know in advance that we were only searching for sequences in a single
##    file with a single sequence (the assembled chromosome 1 of gallus gallus).
##    Small adjustments may be required if this is to change.
##
## TODO
##  * all the code assumes that the matches do not overlap. Since we are
##    dealing with histone genes, this is safe assumption, but will require
##    fixing if to be used in other cases

## Tuning for what is a good match
my $min_pid = 90;  # minimum required value of percent identity
my $min_pln = 0.8; # even if a match is perfect, must be at least as long as this ratio of the query

## sequence file to use to construct the database for search
my $db_data = "gga_ref_Gallus_gallus-4.0_chr1.fa";
## name given to the constructed database
my $db_name = "gallus_gallus_chr1";

## regexp for stem loop (according to PMID:17531405)
our $stlp_seq       = 'GG[CT][CT]CTT[CT]T[CTA]AG[GA]GCC';

## the most common core histone sequences present in the human genome
## as found by our own human histone catalogue
my %common = (
  h2a =>  "MSGRGKQGGKARAKAKTRSSRAGLQFPVGRVHRLLRKGNYAERVGAGAPVYLAA" .
          "VLEYLTAEILELAGNAARDNKKTRIIPRHLQLAIRNDEELNKLLGKVTIAQGGV" .
          "LPNIQAVLLPKKTESHHKAKGK",
  h2b =>  "MPEPAKSAPAPKKGSKKAVTKAQKKDGKKRKRSRKESYSVYVYKVLKQVHPDTG" .
          "ISSKAMGIMNSFVNDIFERIAGEASRLAHYNKRSTITSREIQTAVRLLLPGELA" .
          "KHAVSEGTKAVTKYTSSK",
  h3  =>  "MARTKQTARKSTGGKAPRKQLATKAARKSAPATGGVKKPHRYRPGTVALREIRR" .
          "YQKSTELLIRKLPFQRLVREIAQDFKTDLRFQSSAVMALQEACEAYLVGLFEDT" .
          "NLCAIHAKRVTIMPKDIQLARRIRGERA",
  h4  =>  "MSGRGKGGKGLGKGGAKRHRKVLRDNIQGITKPAIRRLARRGGVKRISGLIYEE" .
          "TRGVLKVFLENVIRDAVTYTEHAKRKTVTAMDVVYALKRQGRTLYGFGG",
);

## This will create the database against we will blast our sequences
## We know a priori that canonical histone genes are present in chicken's
## chromosome 1 (as far as we know, chicken only have a single histone
## cluster), so we can limit the database to that sequence. The sequence
## for the entire chromosome can be downloaded from NCBI's FTP server at:
##  ftp://ftp.ncbi.nih.gov/genomes/Gallus_gallus/Assembled_chromosomes/seq/gga_ref_Gallus_gallus-4.0_chr1.fa.gz
##
Bio::Tools::Run::StandAloneBlastPlus->new(
  -db_data => $db_data,
  -db_name => $db_name,
  -create => 1
)->make_db();

my $fac = Bio::Tools::Run::StandAloneBlastPlus->new(
  -db_name => $db_name,
);

## Two arrays, for the "good" and "bad" HSPs
##
## We will want all the HSP from all the histones in the same array so we
## can sort them by their location in the genome. The problem is that the
## $hsp does not know to which histone search it belongs to. To work
## around this we create 3 element arrays for each HSP, the first element
## is the histone name, the second is the chromosome accession, and the
## third is the HSP object
my @bad;
my @good;

while (my ($histone, $seq) = each %common) {
  ## we need to create a sequence file for input to blast
  my $file = "$histone.gb";
  Bio::SeqIO->new(
    -format => 'fasta',
    -file   => ">$file",
  )->write_seq(Bio::Seq->new(
    -seq        => $seq,
    -display_id => $histone,
  ));

  my $result = $fac->tblastn(
    -query   => $file,
    -outfile => $file . '.bls',
    -method_args => [
      ## turn off low-complexity filter
      ##
      ## From the BLAST help: "This function mask off segments of the query
      ## sequence that have low compositional complexity, ... ". I'm guessing
      ## this means it identifies parts of the protein that are of less
      ## interest, which therefore are also more likely to change, less
      ## important for the alignment, and does not use them for the query at
      ## all. In our specific case, histone sequences, even when the match was
      ## perfect, BLAST refused to align the histone tails (actually it's very
      ## interesting that the model recognized the tails of the histones).
      ## We know, in advance, that for our specific case, the whole sequence
      ## is well conserved throught and important so we can turn it off.
      '-seg' => 'no',
    ],
  );

  ## we only have one sequence in the database so there is will always be
  ## only 1 hit. We would have to place next_hit() into a loop otherwise
  my $hit = $result->next_hit(); # Bio::Search::Hit::HitI compliant object

  ## this will be something like "ref|NC_006088.3| Gallus gallus isolate"
  ## but we want the accession number (NC_006088.3) only
  $hit->name =~ m/ref\|(.*)\|/;
  my $hit_name = $1;

  ## get all High Scoring Pair, then loop through them while
  ## splitting them into the list of good or bad
  my @all = $hit->hsps(); # Bio::Search::HSP::HSPI compliant objects

  my $bad;
  foreach my $hsp (@all) {
    $bad = 1;

    next if ($hsp->percent_identity < $min_pid);
    next if ($hsp->length('total') < length ($seq) * $min_pln);

    ## Check the pair starts at the beginning of the protein.
    ##
    ## We know this is true for our case. If we didn't, we'd have to get
    ## the whole sequence, and look for a possible start codon before it.
    ## In all cases, we are printing a report of all bad matches as well,
    ## so we will still catch anything interesting that we'd be throwing away
    next if ($hsp->start('query') != 1);

    push (@good, [$histone, $hit_name, $hsp]);
    $bad = 0;

  } continue {
    push (@bad, [$histone, $hit_name, $hsp]) if ($bad);
  }
}

## sort the good HSP by chromosome name first,
## and then by start coordinates
@good = sort {
  $a->[1]                   cmp $b->[1]
    or
  $a->[2]->start('subject') <=> $b->[2]->start('subject')
} @good;

## sort the bad HSP by histone type
@bad = sort {$a->[0] cmp $b->[0]} @bad;

## variables that will be used in the printed reports
my $histone;  # the histone type
my $chr;      # accession for the hit (NC_006088.3 for gallus gallus chromosome 1)
my $strand;   # string + or -
my $start;    # coordinates in the subject where the HSP starts
my $end;      # coordinates in the subject where the HSP ends
my $dist;     # distance between the beginning of a HSP and the end of the last HSP
my $seq_ln;   # length of the histone sequence (length of the entire query)
my $length;   # total length of HSP
my $pid;      # percentage identity of the HSP

##
## Print report for the cluster organization
##

format CLUSTER_TOP =
Histone   Chromosome  Strand    Start      End      Distance
------------------------------------------------------------
.
format CLUSTER =
@<<<<<@>>>>>>>>>>>>>@|||||||||@#########@#########@#########
$histone, $chr,       $strand,    $start,     $end,    $dist
.

$^ = 'CLUSTER_TOP';
$~ = 'CLUSTER';
$= = 60;  # set page to 60 characters wide
$- = 0;   # print header again

## set end of the last HSP to the start of the first HSP
my $last_end = $good[0]->[2]->start('subject');
foreach my $set (@good) {
  $histone = $set->[0];
  $chr     = $set->[1];

  my $hsp  = $set->[2];
  $strand  = $hsp->strand('subject') < 0 ? "-" : "+";
  $start   = $hsp->start('subject');
  $end     = $hsp->end('subject');

  ## distance between the end of the last match and
  ## the start of this one
  $dist = $start - $last_end;

  write;
  $last_end = $end;
}


##
## Print report for bad HSP
##

format BADMATCH_TOP =

                     Bad matches

Histone    Query     HSP     Subject     Subject  Percentage
          length  length       start         end    identity
------------------------------------------------------------
.

format BADMATCH =
@<<<<<<<@#######@#######@###########@###########  @##.######
$histone, $seq_ln, $length,   $start,       $end,       $pid
.

$^ = 'BADMATCH_TOP';
$~ = 'BADMATCH';
$= = 60;  # set page to 80 characters wide
$- = 0;   # print header again

foreach my $set (@bad) {
  $histone = $set->[0];
  $chr     = $set->[1];
  my $hsp  = $set->[2];
  $seq_ln  = length ($common{$histone});

  $length = $hsp->length('total');
  $start  = $hsp->start('subject');
  $end    = $hsp->end('subject');
  $pid    = $hsp->percent_identity();
  write;
}

