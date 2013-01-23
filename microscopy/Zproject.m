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

## -*- texinfo -*-
## @deftypefn  {Function File} {} Zproject (@var{Zstack})
## @deftypefnx {Function File} {} Zproject (@var{Zstack}, @var{type})
## @deftypefnx {Function File} {} Zproject (@var{Zstack}, "threshold mean", @var{thresh})
## @deftypefnx {Function File} {} Zproject (@dots{}, @var{Zdim})
## Project stack of images image across Z dimension.
##
## The Z projection of the image @var{Zstack} is done through the dimension
## @var{Zdim}. This allows for multi-channel, time-series, Z-stack images to be
## projected.  By default, @var{Zdim} is the last dimension.
##
## The class of the output image will be the same as the input.
##
## The optional argument @var{type}, specifies the type of Z projection.
##
## @table @asis
## @item "max" (default)
## Each pixel of output image is the maximum intensity of that pixel value
## across the Z stack.  It will maximize the noise in the background but
## preserve details.
##
## @item "mean" or "average"
## Each pixel of output image is the mean of the pixel value across the Z stack.
## Yeld a gray background but loses many details.
##
## @item "median"
## Each pixel of output image is the median of the pixel value across the Z stack.
##
## @item "min"
## Each pixel of output image is the minimum intensity of that pixel value
## across the Z stack.
##
## @item "stdev"
## Each pixel of output image is the standard deviation of the pixel value
## across the Z stack.  It removes background but loses many details.
##
## @item "sum"
## Each pixel of output image is the sum of the pixel value across the Z stack.
## After sum, the image histogram needs top be adjusted for the maximum of the
## sum.  Note that since the output class will be the same of the input, the
## actual pixel value may not be the actual sum, but its intensity will correct
## relative to the sum of other pixels.
##
## @item "threshold mean"
## Each pixel of output image is the mean of the pixel value across the Z stack
## whose intensity is below @var{thresh}.
##
## @item "weighted sum"
## Not yet implemented.
## @end table
## @end deftypefn

function img = Zproject (img, projtype = "max", varargin)

  if (nargin < 1 || nargin > 4)
    print_usage ();
  elseif (! ischar (projtype))
    error ("Zproject: TYPE must be a string.");
  elseif (ndims (img) < 3)
    error ("Zproject: a Z stack needs at least 3 dimensions.");
  endif

  Zdim = ndims (img);
  if (strcmpi (projtype, "threshold mean"))
    if (numel (varargin) < 1 || ! isscalar (varargin{1}) || ! isnumeric (varargin{1}))
      error ("Zproject: TYPE %s requires a scalar threshold value", projtype);
    endif
    thresh = varargin{1};
    if (numel (varargin) == 2)
      Zdim   = varargin{2};
    endif
  elseif (! isempty (varargin))
    Zdim = varargin{1};
  endif

  if (! isscalar (Zdim) || ! isindex (Zdim, ndims (img)) || islogical (Zdim))
    error ("Zproject: ZDIM must be a scalar value less than or equal to the image number of dimensions");
  endif

  Zsize = size (img, Zdim);
  in_cl = class (img);
  img   = im2double (img);
  switch (tolower (projtype))
    case {"average", "mean"}, img = mean (img, Zdim);
    case "median",            img = median (img, Zdim);
    case "max",               img = max (img, [], Zdim);
    case "min",               img = min (img, [], Zdim);
    case "stdev",             img = std (img, 0, Zdim);
    case "sum"
      img = sum (img, Zdim);
      img = mat2gray (img, [0 max(img(:))]);
    case "threshold mean"
      ## casting the threshold value, means that the user can use double, even
      ## when image is of an integer class
      thresh = im2double (cast (thresh, in_cl));
      img(img < thresh) = 0;
      img = mean (img, Zdim);
#    case "weighted sum"
      ##You could use a weighted sum rather than the mean intensity, for example
      ##by multiplying with the squared difference to the mean intensity.
    otherwise
      error ("Zproject: invalid TYPE of projection `%s'.", projtype);
  endswitch
  if (! strcmpi (class (img), in_cl));
    img = feval (["im2" in_cl], img);
  endif
endfunction

%!shared stack, projection
%! stack(:,:,1) = magic (5);
%! stack(:,:,2) = magic (5)';
%! stack(:,:,3) = fliplr (magic (5));
%!
%! projection = [ 174  195   21  149  152
%!                223   85   71  110  202
%!                 96  117  138  159  181
%!                 74  166  205  191   53
%!                124  127  255   81  103];
%!assert (Zproject (uint8 (stack), "sum"), uint8 (projection));
%!
%! projection = [  17   24    4   24   17
%!                 24   14    7   14   23
%!                 22   20   13   20   25
%!                 10   21   20   21   10
%!                 15   18   25   18   11];
%!assert (Zproject (uint8 (stack), "max"), uint8 (projection));
