#! /home/carandraug/.usr/bin/octave -qf
##
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

## takes a single argument which should be a csv file with 2 columns (x on the
## first and y on the second)

## exponential decay function is:
##
## y = y0 * exp(-λ*t)
##
## where:
##   * y0 is value of y at t=0
##   * λ is decay constant
##   * τ (mean lifetime) is τ = 1/λ
##
## We could try to fit this with leasqr (nlinfit in MatLab) but that would be
## stupid when we can just linearize it and do linear regression:
##
##          y = y0 * exp(-λ*t)           <=>
## <=> log(y) = log(y0 * exp(-λ*t))      <=>
## <=> log(y) = log(y0) + log(exp(-λ*t)) <=>
## <=> log(y) = log(y0) + (-λ*t)         <=>
## <=> log(y) = log(y0) - λ*t

if (numel (argv) == 0)
  error ("no data file supplied");
elseif (numel(argv) > 1)
  warning ("more than one argument supplied. Will ignore everything after the first");
endif
filename = argv(){1};

[s, err, msg] = stat (filename);
if (err != 0)
  error ("Unable to stat %s: %s", filename, msg);
endif

data = csvread (filename);
if (ndims (data) !=2 || rows (data) == 2)
  error ("data should be a 2D matrix (rows + columns), but found %i dimensions", ndims (data));
elseif (rows (data) == 2 && columns (data) > 2)
  warning ("found 2 rows rather than 2 columns of data. Tranposing...");
  data = data';
endif

x = data(:,1);
y = log (data(:,2));

coeff          = polyfit (x, y, 1);
decay_constant = coeff(1);
mean_lifetime  = 1/decay_constant;
y0             = exp (coeff(2));

disp (sprintf ("decay constant (lambda) is   %g", decay_constant));
disp (sprintf ("mean lifetime (tau) is       %g", mean_lifetime));
disp (sprintf ("value of y at x=0 is         %g", y0));
disp ("");
disp (sprintf ("Function is y = %g * e^(%g * x)", y0, decay_constant));
disp (sprintf ("In Octave, use @(x) %g * exp(%g * x)", y0, decay_constant));
