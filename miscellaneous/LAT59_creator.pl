#!/usr/bin/perl -w
use 5.010;                                  # Use Perl 5.10
use strict;                                 # Enforce some good programming rules
use Local::LAT_processor;                   # Module to make PDF of the labels for different models

my $format  = "LAT59";                      # page format name
&Local::LAT_processor::do_it_all($format);  # function of the module that takes care of everything
