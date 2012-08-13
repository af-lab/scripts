#!/usr/bin/perl
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

use strict;                     # Enforce some good programming rules
use warnings;                   # Replacement for the -w flag, but lexically scoped

my $dir = "/var/www/labels/temp"; #defines directory to check
my $file;

my $time = time();  # time in seconds since Epoch

opendir (DIR, $dir) or die "Can't opendir $dir: $!";

while (defined($file = readdir(DIR))) {
  my $modtime  = (stat("$dir/$file"))[9];                       # get modify time
  my $diff     = $time - $modtime;                              # difference of times in seconds
  if ($diff > 86400 and (not -l "$dir/$file")) {                # only if file has more than 24 hours and is not a symbolic link
    next if $file =~/^\.\.?$/;                                  # skips special directories . and ..
    unlink("$dir/$file") or die "Can't unlink $dir/$file: $!";  # removes the file
  }
}
closedir(DIR);
