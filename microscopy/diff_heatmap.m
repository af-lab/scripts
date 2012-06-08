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
## @deftypefn {Function File} {} diff_heatmap (@var{a}, @var{b})
## @deftypefnx {Function File} {} diff_heatmap (@var{a}, @var{b}, @var{options})
## @deftypefnx {Function File} {[@var{map}] =} diff_heatmap (@dots{})
## Draw difference between two matrixes on a heatmap.
##
## Given two matrixes (or images), it maps their differences. If no output is
## requested, it draws the map on the current figure. Alternatively,
## it returns @var{map} necessary to draw it with @command{imagesc()}.
##
## The possible @var{options} are:
## @itemize @bullet
## @item @command{thresh} value to threshold an image, algorithm name to pass to
## @command{graythresh}, or a mask. Defaults to imthres default algorithm.
## @item @command{binning} ratio to resize image. Defaults to 1 (no resize).
## @item @command{background} value for background. Use false for black or true
## for white. Defaults to true.
## @item @command{morphology} order of morphological operations to use on mask
## after threshold. It should be a cell array of strings. Valid operation names
## are @command{dilate}, @command{erode} and @command{holes}. Defaults to
## erosion, followed by 2 dilations, one erosion, and finnally a fill holes.
## @end itemize
##
## @example
## @group
## map = diff_heatmap (im1, im2, "binning", 2, "background", false);
## diff_heatmap (im1, im2, "thres", "intermodes")
## diff_heatmap (im1, im2, "thres", 120)
## diff_heatmap (im1, im2, "thres", 120, "morphology", {"erode", "dilate", "holes})
## @end group
## @end example
## @end deftypefn

function [varargout] = diff_heatmap (a, b, varargin)

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
    back, ...
    morph ...
          ] = parseparams (varargin,
                           "thresh",      [],
                           "binning",     1,
                           "background",  true,
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

  ## because bwfill makes it double
  ## XXX this should probably be fixed upstream on image package
  mask = logical (mask);

  a = double (a);
  b = double (b);

  a = normalize (a, mask);
  b = normalize (b, mask);
  ratio = zeros (size (a));

  #{
    The first I wrote this, I was dividing the two images (element by element).
    The idea would be that the more similar the two values were, the closer the
    result would be to 1. The more different, the further away from 1, but this
    would go on both directions (to infinity or to zero depending on which one
    would be on the denominator or divisor. To avoid this, for each element, the
    one with highest value was used on the divisor. This would mean that the new
    image would not show which of the images had higher or lower intensity, but
    we are not interested on it, we only care were the highest differences were.
    
    However, later I found that this approach was misleading. See the following
    two examples. At coordinates j, image A has an intensity value of 0.01 while
    image B a value of 0.02. At coordinates k, image A has an intensity of 0.11
    while image B a value of 0.12. The difference between the j and k is the
    same, however, by dividing them, their similarity values were 0.5 and 0.917
    respectively. What we were doing before was obviously wrong. And the answer
    was sooo simple. What we care is the *difference* between them, to hell for
    their *similiarity* (whatever that is). The piece of code on this block was
    the first wrong code, maybe it will be useful one day.

    ## having zeros makes things weird too. If both images have their minimum on
    ## the same coordinates, we will end up diving 0/0 which returns NaN. Also,
    ## anything that will divide 0, will always return zero, even their values are
    ## quite similar (0/eps is the minimum difference that we can measure but would
    ## still give 0 which means completely different). To avoid this, we make all
    ## instances of zero, the value eps..
    ## this could be in the code of normalize() but I want to make it clear here
    a(a == 0) = eps;
    b(b == 0) = eps;

    min_ind = a < b;
    ratio(min_ind)  = a(min_ind)  ./ b(min_ind);
    ratio(!min_ind) = b(!min_ind) ./ a(!min_ind);
  #}

  ratio = abs (a - b);
  ## some people prefer to have the opposite and have the highest difference
  ## points black rather than black. This can be changed here. Maybe we should
  ## make this an option
#  ratio = imcomplement (ratio);

  if (back)
    ratio(!mask) = 1;
  else
    ratio(!mask) = 0;
  endif

  #{
    start implementation to calculate correlation coefficient. Try plotting
    intensity of each point. If they are the same, they should make a line
    with y = x

    plot (a(mask), b(mask), ".");
    corr2 (a(mask), b(mask))
    indexes = find (ratio < 0.3 & ratio != 0);
    a(indexes)'
    b(indexes)'
  #}

  if (nargout > 0)
    varargout{1} = ratio;
  else
    imagesc (ratio, [0 1]);
  endif

endfunction

function in = normalize (in, mask)
  in(mask) = in(mask) - min(in(mask));
  in(mask) = in(mask) / max(in(mask));
endfunction
