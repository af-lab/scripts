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
## Using @code{cat} and indexing, allows for the display of different images in
## the same montage, or skip some of the images in @var{img}. For example:
##
## @example
## @group
## montage (img(:,:,1:3:end))  # only display each third image
## @end group
##
## @group
## ## display the grayscale img1 and img2 on a montage with 2
## ## columns (img1 on the top column and img2 on the bottom)
## montage (cat (3, img1, img2), [2 size(img1, 3)])
##
## montage (cat (4, img1, img2), [2 size(img1, 4)])  # same for RGB images
##
## ## display img1 and img2 in two columns, a column for each
## montage (cat (3, img1(:,:,1:2:end), img2(:,:,1:2:end),
##                  img1(:,:,2:2:end), img2(:,:,2:2:end)),
##          [size(img1, 3), 2])
## @end group
## @end example
##
## The optional return value @var{h} is a graphics handle to the created image.
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
