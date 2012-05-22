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
## @deftypefn {Function File} {} similarity_heatmap (@var{a}, @var{b})
## @deftypefnx {Function File} {} similarity_heatmap (@var{a}, @var{b}, @var{options})
## @deftypefnx {Function File} {[@var{map}] =} similarity_heatmap (@dots{})
## Draw heatmap of the similarity between two matrixes.
##
## Given two matrixes (or images), it tries to map their similarity. If no
## output is requested, it draws the map on the current figure. Alternatively,
## it returns @var{map} necessary to draw it with @command{imagesc()}.
##
## The possible @var{options} are:
## @itemize @bullet
## @item @command{thresh} value to threshold an image, algorithm name to pass to
## @command{graythresh}, or a mask. Defaults to imthres default algorithm.
## @item @command{binning} ratio to resize image. Defaults to 1 (no resize).
## @item @command{colormap} colormap to use. Defaults to whatever
## @item @command{background} value for background. use false for black or true
## for white. Defaults to false.
## @end itemize
##
## @example
## @group
## map = similarity_heatmap (im1, im2, "binning", 2, "background", false);
## similarity_heatmap (im1, im2, "thres", "intermodes")
## similarity_heatmap (im1, im2, "thres", 120)
## @end group
## @end example
## @end deftypefn

function [varargout] = similarity_heatmap (a, b, varargin)

  if (nargin < 2)
    print_usage;
  elseif (!isnumeric (a) || !ismatrix (a))
    error ("A should be a numeric matrix");
  elseif (!isnumeric (b) || !ismatrix (b))
    error ("B should be a numeric matrix");
  elseif (size (a) != size(b))
    error ("A and B must be of same size")
  endif

  [ ~, ...
    thresh, ...
    bin, ...
    cmap, ...
    back, ...
    morph ...
          ] = parseparams (varargin,
                           "thresh",      [],
                           "binning",     1,
                           "colormap",    colormap,
                           "background",  false,
                           "morphology",  {"erode", "dilate", "dilate", "erode", "holes"}
                           );

  if (!islogical (back) || !isscalar (back))
    error ("value of background should be a single logical value");
  elseif (!isnumeric (bin) || !isscalar (bin))
    error ("value of binning should be a numeric scalar");
  elseif (!iscell (morph))
    error ("morph must be a cell array of strings");
  endif

  if (bin != 1)
    a = imresize (a, 1/bin);
    b = imresize (b, 1/bin);
  endif

  if (islogical (thresh))
    if (size (thresh) != size (a))
      error ("given mask for threshold differs in size from matrixes");
    endif
    mask = thresh;
  elseif (isnumeric (thresh))
    if (isempty (thresh))
      thresh = graythresh (a);
    elseif (!isscalar (thresh))
      error ("value of threshold must be a scalar value")
    endif
    mask  = false (size (a));
    mask(a > thresh) = true;
  elseif (ischar (thresh))
    thresh = graythresh (a, thresh);
    mask  = false (size (a));
    mask(a > thresh) = true;
  else
    error ("value of thres must be either a logical matrix as mask, a threshold value, or name of automatic threshold algorithm for imthres");
  endif

  for i = 1:numel(morph)
    if (!ischar (morph{i}))
      error ("morph must be a cell array of strings");
    endif
    switch lower (morph{i})
      case "dilate",  mask = bwmorph (mask, "dilate");
      case "erode",   mask = bwmorph (mask, "erode");
      case "holes",   mask = bwfill  (mask, "holes");
      otherwise       error ("unknown morhpological operator '%s'");
    endswitch
  endfor

  ## because bwfill makes it double (should fix this upstream)
  mask = logical (mask);

  a = double (a);
  b = double (b);

  a = normalize (a, mask);
  b = normalize (b, mask);

  ## having zeros makes things weird too. If both images have their minimum on
  ## the same coordinates, we will end up diving 0/0 which returns NaN. Also,
  ## anything that will divide 0, will always return zero, even their values are
  ## quite similar (0/eps is the minimum difference that we can measure but would
  ## still give 0 which means completely different). To avoid this, we make all
  ## instances of zero, the value eps..
  ## this could be in the code of normalize() but I want to make it clear here
  a(a == 0) = eps;
  b(b == 0) = eps;

  ratio = zeros (size (a));
  min_ind = a < b;
  ratio(min_ind)  = a(min_ind)  ./ b(min_ind);
  ratio(!min_ind) = b(!min_ind) ./ a(!min_ind);
  if (back)
    ratio(!mask) = 1;
  else
    ratio(!mask) = 0;
  endif

  if (nargout > 0)
    varargout{1} = ratio;
  else
    imagesc (ratio);
  endif

endfunction

function in = normalize (in, mask)
  in(mask) = in(mask) - min(in(mask));
  in(mask) = in(mask) / max(in(mask));
endfunction
