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

## -*- texinfo -*-
## @deftypefn {Function File} {} stack2hyperstack (@var{img}, @var{size}, @var{in}, @var{out})
## Rearrange multi dimensional image.
##
## When an multi-dimensional image is read with @code{imread}, it's returned as
## a MxNx1xP matrix. Different channels, positions and time are discarded.
## Depending on the format used, they might as well be all mixed.
##
## The variable @var{size} must be a vector with the order corresponding to @var{in}.
## The order @var{out} might rearrange that order.
##
## The variables @var{in} and @var{out} must be a string composed of the letters
## c (channel), z (Z-slice), t (time point), and p (position).
##
## @example
## @group
## ## reads and image that is MxNx10 where the last dimension alternates between
## ## the different channels, before changing the z-slice and returns a MxNx2x5
## ## matrix (2 channels and 5 z-slices)
## stack2hyperstack (img, [2 5], "cz", "cz")
## @end group
##
## @group
## ## reads and image that is MxNx100 where the last dimension alternates between
## ## the different channels, then Z-slice and finnaly time. It returns a MxNx2x10x5
## ## matrix
## stack2hyperstack (img, [2 5 10], "czt", "ctz")
## @end group
##
## @end deftypefn

function img = stack2hyperstack (img, vec_size, in = "cztp", out = in)
  ## should we make this a struct instead a ND matrix?
  if (nargin < 2 || nargin > 4)
    print_usage ();
  elseif (! isvector (vec_size) || ! isnumeric (vec_size))
    error ("stack2hyperstack: SIZE must be a numeric vector");
  elseif (! ischar (in) || ! ischar (out))
    error ("stack2hyperstack: order of images must be a string");
  elseif (any (regexpi ([in out], "[^cztp]")))
    error ("stack2hyperstack: only the characters c, z, t and p are allowed.");
  endif

  img = reshape (img, [rows(img) columns(img) vec_size]);
  if (! strcmpi (in, out))
    order = arrayfun (@(x) find (tolower (in) == x), tolower (out)) + 2;
    img = permute (img, [1 2 order]);
  endif
endfunction
