## Copyright (C) 2014 Carnë Draug <carandraug+dev@gmail.com>
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

## -*- texinfo -*-
## @deftypefn {Function File} {} jmsi (@var{x}, @var{y})
## Compute Joint Moment of Standardized Images.
##
## As described in @cite{Demandolx, D. and Davoust, J. (1997), Multicolour
## analysis and local image correlation in confocal microscopy. Journal of
## Microscopy, 185: 21-36. doi: 10.1046/j.1365-2818.1997.1470704.x}.
##
## @seealso{ccri}
## @end deftypefn

function cor = jmsi (x, y, ax = 0, ay = 0, f = fspecial ("gaussian", 9, 1.33))

  if (! size_equal (x, y))
    error ("jmsi: X and Y must be of equal sizes");
  elseif (ndims (x) != 2)
    error ("jmsi: X and Y must have only 2 dimensions");
  endif

  x = im2double (x);
  y = im2double (y);

  xf = conv_filter (x, f);
  yf = conv_filter (y, f);

  xs = (x - xf) ./ fstd (xf, x, f, ax);
  ys = (y - yf) ./ fstd (yf, y, f, ay);

  cor = conv_filter (xs .* ys, f);

endfunction

## filter std
## sqrt of Equation 4 in page 35. Kinda like std for each pixel nhood
function std = fstd (xf, x, f, ax)
  ## Get real part because when variance is very much close to zero, machine
  ## precision creeps in and we may get an almost zero negative value.
  std = real (sqrt (conv_filter (x.^2, f) - (xf.^2) + ax));
endfunction

## the gaussian convolution filter
function xf = conv_filter (x, f)
  xf = imfilter (x, f, "replicate", "conv");
endfunction
