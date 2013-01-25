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
## @deftypefn  {Function File} {} montage (@var{img})
## @deftypefnx {Function File} {} montage (@var{img}, [@var{rows} @var{cols}])
## @deftypefnx {Function File} {@var{h}} montage (@dots{})
## Create montage from N-dimensional image.
##
## The variable @var{img} must be a 3 or 4 dimensional matrix, is last dimension
## used to cycle through its images.  @var{img} will be considered a grayscale
## or RGB image if they have 3 or 4 dimensions respectively.
##
## The optional arguments @var{rows} and @var{cols} must be a 2 element vector
## specifying the number of rows and columns that the montage should display.
## Defaults to 1 row with as many columns as the number of images in @var{img}.
##
## Images from @var{img} will be added to the montage row-wise until reaching
## the limit on the number of displays available.  E.g., if @var{img} has 10
## images and a 3 by 3 montage is requested, the last image (the 10th) will not
## appear on the montage.
##
## The optional return value @var{h} is a graphics handle to the created image.
##
## Using @code{cat}, @code{reshape}, @code{permute} and smart indexing, allows
## for the display of different images in the same montage, or skip some of the images in
## @var{img}. For example:
##
## @example
## @group
## montage (img(:,:,1:3:end))  # only display each third image
## @end group
## @end example
##
## Displaying 2 images on the same montage, each on its row:
## @example
## @group
## montage (cat (3, img1, img2), [2 size(img1, 3)])
## montage (cat (4, img1, img2), [2 size(img1, 4)])  # same for RGB images
## @end group
## @end example
##
## If each image should be displayed on its column, instead, some reshaping is
## necessary to interlace the 2 images.  Following the previous example:
##
## @example
## @group
## ## grayscale images (each 512x512x5)
## img = permute (cat (4, img1, img2), [1 2 4 3])
## montage (reshape (img, [512 512 10]), [5 2])
## ## RGB images (each 512x512x3x5)
## img = permute (cat (5, img1, img2), [1 2 3 5 4])
## montage (reshape (img, [512 512 3 10]), [5 2])
## @end group
## @end example
##
## An example a bit more complicated.  A grayscale image, 512x512 pixels,
## 2 channels, 10 time points and 7 Z-slices.
## @example
## @group
## size (img)
## @result{} 512  512    1    2   10   7
## ## montage with one column per time point
## montage (reshape (img(:,:,:,1,:,:), [512 512 7*10]), [10 7])
## ## montage with 1 row per time point (permute first)
## img = permute (img, [1 2 3 5 4]);
## montage (reshape (img(:,:,:,1,:,:), [512 512 7*10]), [7 10])
## @end group
## @end example
##
## @seealso{image, imshow, subplot}
## @end deftypefn

function handle = montage (img, rc = [1 size(img, ndims (img))])
  ## FIXME we are not supporting indexed images... but who cares about them
  ##       anyway?

  if (nargin < 1 || nargin > 2)
    print_usage ();
  elseif (all (ndims (img) != [3 4]))
    error ("montage: IMG must be a 3 or 4 dimensional matrix");
  elseif (! isnumeric (rc) || numel (rc) != 2 || any (fix (rc) != rc) || ! isindex (rc) || islogical (rc))
    error ("montage: ROWS and COLS must be a 2 element vector of positive integers");
  endif

  imgdim = ndims (img);
  final  = rc(1) * rc(2);

  for idx = 1 : size (img, imgdim)
    if (idx > final)
      break
    endif
    tmp_handle = subplot (rc(1), rc(2), idx);
    switch (imgdim)
      case {3},   imshow (img(:,:,idx));
      case {4},   imshow (img(:,:,:,idx));
      otherwise,  error ("montage: wrong number of IMG dimensions");
    endswitch
  endfor

  if (nargout > 0)
    handle = tmp_handle;
  endif

endfunction
