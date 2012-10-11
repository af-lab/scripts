#!/usr/bin/octave -qf
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

#{
  This script is meant to find the optimal laser settings for activation of
  whatever (it was originally written for PAGFP and mEos2).  The basic idea is
  to use something such as H2B in order to have a large area that can be
  activated and compare the intensity on each pixel after activation with the
  control intensity (something expressed in tandem for PAGFP or the green
  intensity for mEos2).  A single cell expressing H2B-mEos2 could then be used
  to try 2 or 3 different laser settings.
  
  It accepts the directory with the images as last argument.
  
  The laser settings should be encoded on the filename since it's not always
  possible to read it from the file metadata.  Other scripts, to rename the
  files, can be written for those purposes. The expected filename format is:
  
  cell=XX, bleach=x, pixel-dwell=xx.xx, laser-power=xxx, laser-iterations=xx
  
  Spaces between parameter names and comma are optional.
#}

################################################################################
## Options
################################################################################

method = "mean";    ## method to filter the images (mean, median or none)
thresh = "otsu";    ## method for automatic threshold (any used by graythresh)

################################################################################
## Subfunctions
################################################################################

function cleanlist = clean_filelist (filelist)
  cleanlist = {};
  for i = 1:numel(filelist)
    [~, ~, ext]  = fileparts (filelist{i});
    if (strcmp (ext, ".tif")), cleanlist{end+1} = filelist{i}; endif
  endfor
endfunction

function [cell, bleach, dwell, power, iterations] = read_filename (filename)
  [~, name, ext]  = fileparts (filename);
  filename_regexp = "^    cell             = (\\d\\d\\d), ...
                     \\s? bleach           = (\\d), ...
                     \\s? pixel-dwell      = (\\d\\d\\.\\d\\d), ...
                     \\s? laser-power      = (\\d\\d\\d), ...
                     \\s? laser-iterations = (\\d\\d)$";
  [~, ~, ~, ~, tokens] = regexp (name, filename_regexp, "ignorecase", "freespacing");
  ## we set all them to false by default to avoid warnings of missing returned
  ## values and make easier to check if file was read properly
  cell = bleach = dwell = power = iterations = false;
  if (!isempty (tokens))
    cell       = str2double (tokens{1}{1});
    bleach     = str2double (tokens{1}{2});
    dwell      = str2double (tokens{1}{3});
    power      = str2double (tokens{1}{4});
    iterations = str2double (tokens{1}{5});
  else
    warning ("invalid filename `%s'", name);
  endif
endfunction

function img = multipage_read (filename)
  ## FIXME the code only deals with tif files... should port the OMERO toolbox
  ## for Octave and drop this limitation
  img = imread (filename, 1:numel (imfinfo (filename)));
  img = squeeze (img);
endfunction

function mask = getROI (pre, post)
  diff = post - pre;
  mask = im2bw (diff, graythresh (diff, thresh));
  mask = imopen (mask, true (3));
  ## we do not fill holes because we don't care about those locations
endfunction

function [img] = remove_background (img)
  ## Make convolution matrix (square of size 10)
  bg_size = 10;
  bg_mask = ones (bg_size);

  ## FIXME should make this accept any number of dimensions... probably using
  ## size (but using ndims on nthargout)
  for page = 1:4
    ## Find minimum of the convolution matrix
    ## If there's more than one vale in the convolved matrix with the minimum value,
    ## it gives only the first one
    conv_matrix  = conv2 (double (img(:,:,page)), bg_mask, 'valid');
    [sRow, sCol] = find (conv_matrix == min (conv_matrix(:)), 1, 'first');
    img(:,:,page) = img(:,:,page) - mean (img(sRow:sRow+bg_size-1,sCol:sCol+bg_size-1,page)(:));
  endfor
endfunction

################################################################################
## Start script / End subfunctions
################################################################################

## find which of the options is a directory...
options = argv ();
files   = "";
for i = numel (options) :-1:1
  ## FIXME: argv also returns the options used by octave some of them might have
  ## paths involved. How can we skip them? A good guess is that the last one to be
  ## defined is the one that matters the most for us
  if (exist (options{i}, "dir"))
    dirname = options{i};
    [files, err, msg] = readdir (dirname);
    if (err), error ("unable to readdir `%s': %s\n", dirname, msg); endif
    break
  endif
endfor
if (isempty (files)), error ("No directory to search for images...\n"); endif

files = clean_filelist (files);
data  = struct ();
for i = 1:numel (files)
  [data(i).cell, data(i).bleach, data(i).dwell, data(i).power, data(i).iterations] = read_filename (files{i});
  if (!data(i).cell), continue; endif  ## skip invalid files
  img = multipage_read ([dirname files{i}]);
  for j = 1:size (img, 3);
    img(:,:,j) = medfilt2 (img(:,:,j));
  endfor
  ## calculate ROI (activated area) from the 1st channel (should be the one that
  ## is being activated; green for PAGFP, red for mEos2
  roi = getROI (img(:,:,1), img(:,:,3));
  img = remove_background (img);

  ## post activated by pre control (red for MaryI, green for mEos2)
  activation = (double(img(:,:,3)) / double(img(:,:,2)))(roi);
  data(i).mean = mean (activation);
  data(i).std  = std (activation);
endfor

## build grid
for iterations = 1:14
  for power = 1:14
    mask  = ([data.iterations] == iterations & [data.power] == power);
    means(iterations, power) = mean ([data(mask).mean]);
  endfor
endfor
