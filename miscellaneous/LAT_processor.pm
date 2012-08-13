package Local::LAT_processor;
## Copyright (C) 2010 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

use 5.010;                                  # use Perl 5.10
use strict;                                 # enforce some good programming rules
use warnings;                               # replacement for the command line flag -w , but limited to the enclosing block
our (@ISA, @EXPORT, @EXPORT_OK, $VERSION);  # must be package global variables for Exporter
use Exporter;                               # handle module's external interface
$VERSION    = 0.90;
@ISA        = qw(Exporter);                 # inherit import method from Exporter
@EXPORT     = qw();                         # export nothing automatically
@EXPORT_OK  = qw(&do_it_all);               # export only these and by request

use File::Temp qw(tempfile);                # create and open temporary files in a safe way
use Regexp::Common;                         # provides commonly requested regular expressions (debian package is libregexp-common-perl)
use CGI;                                    # process and prepare HTTP requests and responses
## Avoiding Denial of Service Attacks
$CGI::DISABLE_UPLOADS = 1;
$CGI::POST_MAX        = 102_400; # 100KB

## Set all variables needed
my $latexpath             = "/usr/bin/pdflatex";          # location of LaTeX compiler
my $apache_root           = "/var/www/";                  # path to apache root
my $temp_path             = "labels/temp/";               # relative path (to apache root) of the directory for temp files


sub do_it_all {
  my $format    = shift @_;
  my $data      = &get_format_specificities ($format);
  my $cgi       = CGI->new;                               # get data coming from POST and GET
  &process_input($cgi, $data);                            # process the data coming from CGI
  my ($tex_fh,
      $tex_path,
      $pdf_url) = &get_paths($cgi, $data);                # create texfile, filehandle, and calculate future URL for pdf

  &generate_tex($data, $tex_fh);                          # generate latex code

  ## Compile the LaTeX code on nonstop mode. Must define output directory to avoid
  ## having to chdir before. Also must redirect STDOUT to /dev/null or it gets
  ## sent to the web server as the HTTP response
  system("$latexpath -interaction=nonstopmode -output-directory ${apache_root}${temp_path} $tex_path > /dev/null");
  print $cgi->redirect("$pdf_url");                       # send user to PDF file
}

################################################################################
## Non-shared subroutines
################################################################################

## Depending on the format of the page, returns a data structure with that model
## specification. Here's the list of keys returned and their explanation
## format   = name of format
## rows     = number of rows
## columns  = number of columns
## width    = width in mm of each text block
## x start  = X distance of first label from top left corner of page
## y start  = Y distance of first label from top left corner of page

sub get_format_specificities {
  my %data;
  $data{"format"} = shift @_;
  if ($data{"format"} eq "LAT59") {
    $data{"rows"}     = 16;
    $data{"columns"}  = 3;
    $data{"width"}    = 23.5;
    $data{"x start"}  = "7.62mm";
    $data{"y start"}  = "22.23mm";
    $data{'coordinates'}{'1,1'}{'position'}   = '1,1';
    $data{'coordinates'}{'1,10'}{'position'}  = '1,137.8';
    $data{'coordinates'}{'1,11'}{'position'}  = '1,153';
    $data{'coordinates'}{'1,12'}{'position'}  = '1,168.2';
    $data{'coordinates'}{'1,13'}{'position'}  = '1,183.4';
    $data{'coordinates'}{'1,14'}{'position'}  = '1,198.6';
    $data{'coordinates'}{'1,15'}{'position'}  = '1,213.8';
    $data{'coordinates'}{'1,16'}{'position'}  = '1,229';
    $data{'coordinates'}{'1,2'}{'position'}   = '1,16.2';
    $data{'coordinates'}{'1,3'}{'position'}   = '1,31.4';
    $data{'coordinates'}{'1,4'}{'position'}   = '1,46.6';
    $data{'coordinates'}{'1,5'}{'position'}   = '1,61.8';
    $data{'coordinates'}{'1,6'}{'position'}   = '1,77';
    $data{'coordinates'}{'1,7'}{'position'}   = '1,92.2';
    $data{'coordinates'}{'1,8'}{'position'}   = '1,107.4';
    $data{'coordinates'}{'1,9'}{'position'}   = '1,122.6';
    $data{'coordinates'}{'2,1'}{'position'}   = '69.5,1';
    $data{'coordinates'}{'2,10'}{'position'}  = '69.5,137.8';
    $data{'coordinates'}{'2,11'}{'position'}  = '69.5,153';
    $data{'coordinates'}{'2,12'}{'position'}  = '69.5,168.2';
    $data{'coordinates'}{'2,13'}{'position'}  = '69.5,183.4';
    $data{'coordinates'}{'2,14'}{'position'}  = '69.5,198.6';
    $data{'coordinates'}{'2,15'}{'position'}  = '69.5,213.8';
    $data{'coordinates'}{'2,16'}{'position'}  = '69.5,229';
    $data{'coordinates'}{'2,2'}{'position'}   = '69.5,16.2';
    $data{'coordinates'}{'2,3'}{'position'}   = '69.5,31.4';
    $data{'coordinates'}{'2,4'}{'position'}   = '69.5,46.6';
    $data{'coordinates'}{'2,5'}{'position'}   = '69.5,61.8';
    $data{'coordinates'}{'2,6'}{'position'}   = '69.5,77';
    $data{'coordinates'}{'2,7'}{'position'}   = '69.5,92.2';
    $data{'coordinates'}{'2,8'}{'position'}   = '69.5,107.4';
    $data{'coordinates'}{'2,9'}{'position'}   = '69.5,122.6';
    $data{'coordinates'}{'3,1'}{'position'}   = '138,1';
    $data{'coordinates'}{'3,10'}{'position'}  = '138,137.8';
    $data{'coordinates'}{'3,11'}{'position'}  = '138,153';
    $data{'coordinates'}{'3,12'}{'position'}  = '138,168.2';
    $data{'coordinates'}{'3,13'}{'position'}  = '138,183.4';
    $data{'coordinates'}{'3,14'}{'position'}  = '138,198.6';
    $data{'coordinates'}{'3,15'}{'position'}  = '138,213.8';
    $data{'coordinates'}{'3,16'}{'position'}  = '138,229';
    $data{'coordinates'}{'3,2'}{'position'}   = '138,16.2';
    $data{'coordinates'}{'3,3'}{'position'}   = '138,31.4';
    $data{'coordinates'}{'3,4'}{'position'}   = '138,46.6';
    $data{'coordinates'}{'3,5'}{'position'}   = '138,61.8';
    $data{'coordinates'}{'3,6'}{'position'}   = '138,77';
    $data{'coordinates'}{'3,7'}{'position'}   = '138,92.2';
    $data{'coordinates'}{'3,8'}{'position'}   = '138,107.4';
    $data{'coordinates'}{'3,9'}{'position'}   = '138,122.6';
  } elsif ($data{"format"} eq "LAT7") {
    $data{"rows"}     = 20;
    $data{"columns"}  = 7;
    $data{"width"}    = 23.5;
    $data{"x start"}  = "11.43mm";
    $data{"y start"}  = "22.70mm";
    $data{'coordinates'}{'1,1'}{'position'}   = '1,1';
    $data{'coordinates'}{'1,2'}{'position'}   = '1,13.7';
    $data{'coordinates'}{'1,3'}{'position'}   = '1,26.4';
    $data{'coordinates'}{'1,4'}{'position'}   = '1,39.1';
    $data{'coordinates'}{'1,5'}{'position'}   = '1,51.8';
    $data{'coordinates'}{'1,6'}{'position'}   = '1,64.5';
    $data{'coordinates'}{'1,7'}{'position'}   = '1,77.2';
    $data{'coordinates'}{'1,8'}{'position'}   = '1,89.9';
    $data{'coordinates'}{'1,9'}{'position'}   = '1,102.6';
    $data{'coordinates'}{'1,10'}{'position'}  = '1,115.3';
    $data{'coordinates'}{'1,11'}{'position'}  = '1,128';
    $data{'coordinates'}{'1,12'}{'position'}  = '1,140.7';
    $data{'coordinates'}{'1,13'}{'position'}  = '1,153.4';
    $data{'coordinates'}{'1,14'}{'position'}  = '1,166.1';
    $data{'coordinates'}{'1,15'}{'position'}  = '1,178.8';
    $data{'coordinates'}{'1,16'}{'position'}  = '1,191.5';
    $data{'coordinates'}{'1,17'}{'position'}  = '1,204.2';
    $data{'coordinates'}{'1,18'}{'position'}  = '1,216.9';
    $data{'coordinates'}{'1,19'}{'position'}  = '1,229.6';
    $data{'coordinates'}{'1,20'}{'position'}  = '1,242.3';
    $data{'coordinates'}{'2,1'}{'position'}   = '29,1';
    $data{'coordinates'}{'2,2'}{'position'}   = '29,13.7';
    $data{'coordinates'}{'2,3'}{'position'}   = '29,26.4';
    $data{'coordinates'}{'2,4'}{'position'}   = '29,39.1';
    $data{'coordinates'}{'2,5'}{'position'}   = '29,51.8';
    $data{'coordinates'}{'2,6'}{'position'}   = '29,64.5';
    $data{'coordinates'}{'2,7'}{'position'}   = '29,77.2';
    $data{'coordinates'}{'2,8'}{'position'}   = '29,89.9';
    $data{'coordinates'}{'2,9'}{'position'}   = '29,102.6';
    $data{'coordinates'}{'2,10'}{'position'}  = '29,115.3';
    $data{'coordinates'}{'2,11'}{'position'}  = '29,128';
    $data{'coordinates'}{'2,12'}{'position'}  = '29,140.7';
    $data{'coordinates'}{'2,13'}{'position'}  = '29,153.4';
    $data{'coordinates'}{'2,14'}{'position'}  = '29,166.1';
    $data{'coordinates'}{'2,15'}{'position'}  = '29,178.8';
    $data{'coordinates'}{'2,16'}{'position'}  = '29,191.5';
    $data{'coordinates'}{'2,17'}{'position'}  = '29,204.2';
    $data{'coordinates'}{'2,18'}{'position'}  = '29,216.9';
    $data{'coordinates'}{'2,19'}{'position'}  = '29,229.6';
    $data{'coordinates'}{'2,20'}{'position'}  = '29,242.3';
    $data{'coordinates'}{'3,1'}{'position'}   = '57,1';
    $data{'coordinates'}{'3,2'}{'position'}   = '57,13.7';
    $data{'coordinates'}{'3,3'}{'position'}   = '57,26.4';
    $data{'coordinates'}{'3,4'}{'position'}   = '57,39.1';
    $data{'coordinates'}{'3,5'}{'position'}   = '57,51.8';
    $data{'coordinates'}{'3,6'}{'position'}   = '57,64.5';
    $data{'coordinates'}{'3,7'}{'position'}   = '57,77.2';
    $data{'coordinates'}{'3,8'}{'position'}   = '57,89.9';
    $data{'coordinates'}{'3,9'}{'position'}   = '57,102.6';
    $data{'coordinates'}{'3,10'}{'position'}  = '57,115.3';
    $data{'coordinates'}{'3,11'}{'position'}  = '57,128';
    $data{'coordinates'}{'3,12'}{'position'}  = '57,140.7';
    $data{'coordinates'}{'3,13'}{'position'}  = '57,153.4';
    $data{'coordinates'}{'3,14'}{'position'}  = '57,166.1';
    $data{'coordinates'}{'3,15'}{'position'}  = '57,178.8';
    $data{'coordinates'}{'3,16'}{'position'}  = '57,191.5';
    $data{'coordinates'}{'3,17'}{'position'}  = '57,204.2';
    $data{'coordinates'}{'3,18'}{'position'}  = '57,216.9';
    $data{'coordinates'}{'3,19'}{'position'}  = '57,229.6';
    $data{'coordinates'}{'3,20'}{'position'}  = '57,242.3';
    $data{'coordinates'}{'4,1'}{'position'}   = '85,1';
    $data{'coordinates'}{'4,2'}{'position'}   = '85,13.7';
    $data{'coordinates'}{'4,3'}{'position'}   = '85,26.4';
    $data{'coordinates'}{'4,4'}{'position'}   = '85,39.1';
    $data{'coordinates'}{'4,5'}{'position'}   = '85,51.8';
    $data{'coordinates'}{'4,6'}{'position'}   = '85,64.5';
    $data{'coordinates'}{'4,7'}{'position'}   = '85,77.2';
    $data{'coordinates'}{'4,8'}{'position'}   = '85,89.9';
    $data{'coordinates'}{'4,9'}{'position'}   = '85,102.6';
    $data{'coordinates'}{'4,10'}{'position'}  = '85,115.3';
    $data{'coordinates'}{'4,11'}{'position'}  = '85,128';
    $data{'coordinates'}{'4,12'}{'position'}  = '85,140.7';
    $data{'coordinates'}{'4,13'}{'position'}  = '85,153.4';
    $data{'coordinates'}{'4,14'}{'position'}  = '85,166.1';
    $data{'coordinates'}{'4,15'}{'position'}  = '85,178.8';
    $data{'coordinates'}{'4,16'}{'position'}  = '85,191.5';
    $data{'coordinates'}{'4,17'}{'position'}  = '85,204.2';
    $data{'coordinates'}{'4,18'}{'position'}  = '85,216.9';
    $data{'coordinates'}{'4,19'}{'position'}  = '85,229.6';
    $data{'coordinates'}{'4,20'}{'position'}  = '85,242.3';
    $data{'coordinates'}{'5,1'}{'position'}   = '113,1';
    $data{'coordinates'}{'5,2'}{'position'}   = '113,13.7';
    $data{'coordinates'}{'5,3'}{'position'}   = '113,26.4';
    $data{'coordinates'}{'5,4'}{'position'}   = '113,39.1';
    $data{'coordinates'}{'5,5'}{'position'}   = '113,51.8';
    $data{'coordinates'}{'5,6'}{'position'}   = '113,64.5';
    $data{'coordinates'}{'5,7'}{'position'}   = '113,77.2';
    $data{'coordinates'}{'5,8'}{'position'}   = '113,89.9';
    $data{'coordinates'}{'5,9'}{'position'}   = '113,102.6';
    $data{'coordinates'}{'5,10'}{'position'}  = '113,115.3';
    $data{'coordinates'}{'5,11'}{'position'}  = '113,128';
    $data{'coordinates'}{'5,12'}{'position'}  = '113,140.7';
    $data{'coordinates'}{'5,13'}{'position'}  = '113,153.4';
    $data{'coordinates'}{'5,14'}{'position'}  = '113,166.1';
    $data{'coordinates'}{'5,15'}{'position'}  = '113,178.8';
    $data{'coordinates'}{'5,16'}{'position'}  = '113,191.5';
    $data{'coordinates'}{'5,17'}{'position'}  = '113,204.2';
    $data{'coordinates'}{'5,18'}{'position'}  = '113,216.9';
    $data{'coordinates'}{'5,19'}{'position'}  = '113,229.6';
    $data{'coordinates'}{'5,20'}{'position'}  = '113,242.3';
    $data{'coordinates'}{'6,1'}{'position'}   = '141,1';
    $data{'coordinates'}{'6,2'}{'position'}   = '141,13.7';
    $data{'coordinates'}{'6,3'}{'position'}   = '141,26.4';
    $data{'coordinates'}{'6,4'}{'position'}   = '141,39.1';
    $data{'coordinates'}{'6,5'}{'position'}   = '141,51.8';
    $data{'coordinates'}{'6,6'}{'position'}   = '141,64.5';
    $data{'coordinates'}{'6,7'}{'position'}   = '141,77.2';
    $data{'coordinates'}{'6,8'}{'position'}   = '141,89.9';
    $data{'coordinates'}{'6,9'}{'position'}   = '141,102.6';
    $data{'coordinates'}{'6,10'}{'position'}  = '141,115.3';
    $data{'coordinates'}{'6,11'}{'position'}  = '141,128';
    $data{'coordinates'}{'6,12'}{'position'}  = '141,140.7';
    $data{'coordinates'}{'6,13'}{'position'}  = '141,153.4';
    $data{'coordinates'}{'6,14'}{'position'}  = '141,166.1';
    $data{'coordinates'}{'6,15'}{'position'}  = '141,178.8';
    $data{'coordinates'}{'6,16'}{'position'}  = '141,191.5';
    $data{'coordinates'}{'6,17'}{'position'}  = '141,204.2';
    $data{'coordinates'}{'6,18'}{'position'}  = '141,216.9';
    $data{'coordinates'}{'6,19'}{'position'}  = '141,229.6';
    $data{'coordinates'}{'6,20'}{'position'}  = '141,242.3';
    $data{'coordinates'}{'7,1'}{'position'}   = '169,1';
    $data{'coordinates'}{'7,2'}{'position'}   = '169,13.7';
    $data{'coordinates'}{'7,3'}{'position'}   = '169,26.4';
    $data{'coordinates'}{'7,4'}{'position'}   = '169,39.1';
    $data{'coordinates'}{'7,5'}{'position'}   = '169,51.8';
    $data{'coordinates'}{'7,6'}{'position'}   = '169,64.5';
    $data{'coordinates'}{'7,7'}{'position'}   = '169,77.2';
    $data{'coordinates'}{'7,8'}{'position'}   = '169,89.9';
    $data{'coordinates'}{'7,9'}{'position'}   = '169,102.6';
    $data{'coordinates'}{'7,10'}{'position'}  = '169,115.3';
    $data{'coordinates'}{'7,11'}{'position'}  = '169,128';
    $data{'coordinates'}{'7,12'}{'position'}  = '169,140.7';
    $data{'coordinates'}{'7,13'}{'position'}  = '169,153.4';
    $data{'coordinates'}{'7,14'}{'position'}  = '169,166.1';
    $data{'coordinates'}{'7,15'}{'position'}  = '169,178.8';
    $data{'coordinates'}{'7,16'}{'position'}  = '169,191.5';
    $data{'coordinates'}{'7,17'}{'position'}  = '169,204.2';
    $data{'coordinates'}{'7,18'}{'position'}  = '169,216.9';
    $data{'coordinates'}{'7,19'}{'position'}  = '169,229.6';
    $data{'coordinates'}{'7,20'}{'position'}  = '169,242.3';
  } else {
    die "Unexpected format $data{'format'} found!";
  }
  return \%data;
}

## Retrieved the data sent with CGI and process it all
sub process_input {
  my $cgi   = shift @_;
  my $data  = shift @_;

  ## get RGB values and remove from param list to avoid problems
  ${$data}{'RGB values'}{'red'}   = $cgi->param("red-value");
  ${$data}{'RGB values'}{'green'} = $cgi->param("green-value");
  ${$data}{'RGB values'}{'blue'}  = $cgi->param("blue-value");
  $cgi->delete("red-value","green-value","blue-value");

  ## check if all the values found are real numbers between 0 and 255 and if not,
  ## set that value to zero
  while (my ($color, $value) = each %{${$data}{'RGB values'}} ) {
    unless ($value =~ m{^$RE{num}{real}$} && $value >= 0 && $value <= 255) {
      warn "An unexpected value $value was found for $color value. Setting it to zero";
      $value = 0;
    }
  }

  ## get all remaining entries. If name exists in the hash of coordinates, assign
  ## its value as text
  my %labels = $cgi->Vars;
  while (my ($name, $text) = each %labels) {
    if (exists( ${$data}{'coordinates'}{$name} )){                              ## XXX if text for entries needs to be modified, it's here
      $text =~ s/\\end{verbatim}/\\end {verbatim}/g;
      ${$data}{'coordinates'}{$name}{'text'} = $text;
    } else {
      warn "An unidentified entry with name $name was found when processing the data retrieved by GCI";
      delete($labels{$name});
    }
  }
}

sub get_paths {
  my $cgi   = shift @_;
  my $data  = shift @_;
  my $domain_url      = $cgi->url(-base => 1);

  ## Create temporary directories
  my $dir             = $apache_root . $temp_path;
  my ($tex, $texpath) = tempfile("${$data}{'format'}XXXXXX", DIR => $dir, SUFFIX => '.tex');
  ## Calculate the URL for pdf. Replace the extension tex by pdf and the path
  ## until the apache root by the url of the domain
  my $pdfurl  = $texpath;
  $pdfurl     =~ s/tex$/pdf/i;
  $pdfurl     =~ s/^$apache_root/$domain_url\//i;

  return ($tex, $texpath, $pdfurl);
}

sub generate_tex {
  my $data = shift @_;
  my $fh   = shift @_;

  ## sets the RGB values on a string and separated by a comma
  my $rgb = "${$data}{'RGB values'}{'red'},${$data}{'RGB values'}{'green'},${$data}{'RGB values'}{'blue'}";

  ## Start LaTeX document
  my @preamble = <DATA>;
  print $fh @preamble;
  say $fh '  \definecolor{custom}{RGB}{'.$rgb.'}';
  say $fh '  \textblockorigin{'.${$data}{'x start'}.'}{'.${$data}{'y start'}.'}';

  say $fh '\begin{document}';

  ## Add labels to LaTeX document
  while (my $name = each %{${$data}{'coordinates'}}) {
    next if !${$data}{'coordinates'}{$name}{'text'};
    my $position  = ${$data}{'coordinates'}{$name}{'position'};
    my $text      = ${$data}{'coordinates'}{$name}{'text'};
    say $fh '\begin{textblock}{'.${$data}{'width'}.'}('.$position.') \color{custom}';
    say $fh '\begin{verbatim}';
    say $fh "$text";
    say $fh '\end{verbatim}';
    say $fh '\end{textblock}';
  }
  ## End LaTeX document
  say $fh '\end{document}';
}

1;  #return value of a module must be true
__DATA__
\documentclass[letterpaper,8pt]{extarticle}

\pagestyle{empty}
\setlength{\parindent}{0pt}                % gets rid of advance at first line

\usepackage{setspace}                      % set line spacing
  \setstretch{0.6}                         % sets line spacing to 60%

\usepackage[absolute]{textpos}             % absolute positioning of images and/or text
  \setlength{\TPHorizModule}{1mm}          % textpos configuration. Horizontal units set to 1mm
  \setlength{\TPVertModule}{1mm}           % textpos configuration. Vertical units set to 1mm

\usepackage{color}                         % for coloring
%% The rest of code was page dependent and inserted automatically by the perl script
%% textblockorigin sets the the reference coordinates to the other coordinates

