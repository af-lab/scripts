#!/usr/local/bin/octave -qf
## Copyright (C) 2010, 2012, 2014 Carnë Draug <carandraug+dev@gmail.com>
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

pkg load image; # we need this for imcrop and normxcorr2
pkg_desc = pkg ("describe", "image");
if (! compare_versions (pkg_desc{1}.version, "2.2.0", ">="))
  ## for imcrop to return the second output argument
  error ("Octave Forge image package version 2.2.1 or later is required");
endif

#{
  This script attempts to track a feature through a time-series image. At the
  moment it has no support for Z-stacks though it should be relatively easy to
  implement that. Contact the author if you wish so. Alternatively, in most
  cases of fluorescent microscopy a Z-projection can be used for the
  tracking. To so in Octave, use max() through the Z dimension.

  This script looks for the maximum on the normalized cross correlation matrix.
  For performance this is performed only in the area close to position of the
  feature on the previous time point. This also allows for a single feature to
  be tracked when similar are present on the same image.

  The original position of the feature needs to be specified. As such, the
  first time point will be displayed on a window for selection. In the future
  it may be possible to use an image as input or in the case of multiple images,
  display all at the start before attempting the tracking.

  Know problems: when 2 features contact each other, this script may follow the
  new object instead of the original.
#}

################################################################################
## Options
################################################################################

## Size of the search space for best match
## Value of 0.2 searches in area 20% larger than template
opt.ratio = 0.2;

## Limit tracking to these many frames (set to zero to use all)
opt.nFrames = 0;

################################################################################
## crop_reg - the function which actually does everything
################################################################################

function seed = crop_reg (img, seed, rect, ratio)

  nFrames = size (img, 4);
  if (size (img, 3) != 1)
    error ("CropReg: not a grayscale image. 3rd dimension must be size 1");
  elseif (nFrames <= 1)
    error ("CropReg: not a multi-dimensional image. singleton 4th dimension");
  endif
  img = squeeze (img); # just for less typing ":"
  rimg = rows (img);
  cimg = columns (img);

  ## expand output image for all the frames
  seed = resize (seed, rows (seed), columns (seed), nFrames);

  ## There are two boxes we need to keep track of:
  ##  1) seed = the box with what we will return
  ##  2) search = the slightly larger box where we will be looking
  ##
  ## At any given time, there will be a position vector defining those
  ## boxes relative to the input original image:
  ##    v(1) = x_ini
  ##    v(2) = y_ini
  ##    v(3) = width
  ##    v(4) = length

  ## position vector for the seed
  vseed = [round(rect([1 2])) size(seed)([2 1])];

  ## position vector for the search
  pad = round ((vseed(3:4) * ratio));
  vsearch(3:4) = vseed(3:4) + pad*2;

  for frame = 2:nFrames

    ## readjust the search box and confirm it is still within the limits
    vsearch(1:2) = vseed(1:2) - pad;
    if (vsearch(1) + vsearch(3) > cimg || vsearch(1) < 1 ||
        vsearch(2) + vsearch(4) > rimg || vsearch(2) < 1 )
      ## we could readjust this if in the future we get objects moving
      ## near the borders that we want to track. At the moment, all our
      ## cases still move within the center
      error ("CropReg: object is moving outside of the image")
    endif

    ## look into the search box for the image found on the previous frame
    csr = vsearch(1) : vsearch(1)+vsearch(3)-1;
    rsr = vsearch(2) : vsearch(2)+vsearch(4)-1;
    xc2 = normxcorr2 (seed(:,:,frame-1), img(rsr,csr,frame));

    [~, max_idx] = max (xc2(:));
    [m, n] = ind2sub (size (xc2), max_idx);

    ## recalculate the initial x and y coordinates for the seed
    vseed(1) = vsearch(1) + n - vseed(3);
    vseed(2) = vsearch(2) + m - vseed(4);

    csd = vseed(1) : vseed(1)+vseed(3)-1;
    rsd = vseed(2) : vseed(2)+vseed(4)-1;
    seed(:,:,frame) = img(rsd, csd, frame);
  endfor

  ## put it back into 4D matrix for writing
  seed = reshape (seed, [size(seed)(1:2) 1 nFrames]);

endfunction

################################################################################
## Start script
################################################################################

## All we do here is cycle through each file and ask to select the object
## in the first frame of the image

for file_idx = 1:numel (argv ())
  fpath = argv (){file_idx};

  if (opt.nFrames == 0)
    opt.nFrames = "all";
  else
    opt.nFrames = 1:opt.nFrames;
  endif
  img = imread (fpath, "Index", opt.nFrames);

  printf (["Select ROI to track from frame #1\n" ...
           "(first click in top left corner; second click in bottom right corner.)\n"]);
  [~, rect] = imcrop (imadjust (im2double (img(:,:,:,1))));

  [seed, rect] = imcrop (img(:,:,:,1), rect);

  tracked = crop_reg (img, seed, rect, opt.ratio);

  [fdir, fname, fext] = fileparts (fpath);
  imwrite (tracked, fullfile (fdir, [fname "-tracked" fext]));
endfor

## this tests the function, not the script

%!test
%! ## create test image with disk moving around
%! a = zeros (100, 100, 1, 50, "uint8");
%! d = fspecial ("disk", 3) > 0;
%! d = im2uint8 (d);
%! x = y = 47;
%! for i = 1:50
%!   a(x:x+6, y:y+6, 1, i) = d;
%!   x += randi([-3 3]);
%!   y += randi([-3 3]);
%! endfor
%!
%! ## create the "selected" box
%! seed = zeros (12, 12, "uint8");
%! seed(2:8, 3:9) = d;
%!
%! ## check if it works
%! tracked = crop_reg (a, seed, [44 44 12 12], 0.4);
%! for i = 1:50
%!   assert (tracked(:,:,i), seed);
%! endfor

