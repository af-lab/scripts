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
use File::Temp qw(tempfile);
use CGI qw/:standard :cgi/;

$CGI::POST_MAX        = 1024 * 100; # max 100K posts
$CGI::DISABLE_UPLOADS = 1;          # no uploads

## This script gets data from a html form and uses it to create a password file
## that can be used by Apache to autheticate users. It creates a new file for
## each new user and mails the system administrator. It is his job to use that
## file (created with File::Temp) to add to the list of authorized users.
##
## Notes: htpasswd is run in batch mode

################################################################################
## Options
################################################################################

my $pass_min    = 4;                    # Minimum password length
my $user_min    = 4;                    # Minimum username length

my $htpasswd    = "/usr/bin/htpasswd";  # Absolute path fpr htpasswd
my $encryption  = "-m";                 # See man htpasswd(1)

my $tmp_dir     = "/var/www/svn/temp/"; # Directory to store the temporary files

################################################################################
## Get values from form (field name is argument for param)
################################################################################

my $repo      = param("repository");
my $username  = param("username");
my $pass_1    = param("password1");
my $pass_2    = param("password2");
my $name      = param("real_name");

################################################################################
## No user configuration beyond this point
################################################################################

## Create temporary file to store user information
my (undef, $passwd_file) = tempfile(DIR => $tmp_dir);

## Server side to check some conditions
if ($pass_1 ne $pass_2) {
  reply_error("The passwords were different.");
} elsif (length($pass_1) < $pass_min) {
  reply_error("The passwords were smaller than 4 characters.");
} elsif (length($username) < $user_min) {
  reply_error("The username had less than 4 characters.");
}

## Create command and run htpasswd
my @htpasswd_command = (
                     $htpasswd,
                     "-b",
                     "-c",
                     $encryption,
                     $passwd_file,
                     $username,
                     $pass_1,
                     );

system(@htpasswd_command);
if ($? != 0) {
  reply_error(sprintf "Error when registering user. Error value is %d\n", $? >> 8);
} else {
  reply_success();
}

################################################################################
## Subroutines
################################################################################

sub reply_error {
  my $msg = $_[0];
  print
    header,
    h4("$msg"),
    "You should mention this to the system administrator",
    end_html;
  exit;
}

sub reply_success {
  print
    header,
    h4("Contact the system administrator to activate your account."),
    "User $username was successfully registered.",
    end_html;
  exit;
}
