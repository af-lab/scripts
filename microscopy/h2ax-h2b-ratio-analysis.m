#! /usr/local/bin/octave -qf
## Copyright (C) 2013-2015 Carnë Draug <carandraug+dev@gmail.com>
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

pkg load image;
pkg load statistics;
pkg load imagej;

graphics_toolkit ("qt");
set (0, "defaultfigurevisible", "off");

## Read and correct our images.
##
## Our images have 3 channels and a Z stack, ordered DAPI, H2AX-GFP,
## and H2B-RFP.  They also show some chromatic aberration on the DAPI
## channel.
function [dapi, h2ax, h2b] = read_image (fpath)
  nFrames = numel (imfinfo (fpath));
  if (rem (nFrames, 3) != 0)
    error ("File `%s' does not have Nx3 frames", fpath);
  endif
  img = imread (fpath, "Index", "all");
  ## crop the left border which is rubbish (why?)
  img(:, 1:50,:,:) = [];

  dapi  = img(:,:,:,1:3:nFrames);
  h2ax  = img(:,:,:,2:3:nFrames); # H2AX-GFP
  h2b   = img(:,:,:,3:3:nFrames); # H2B-RFP

  ## To account for chromatic aberration on the DAPI channel.
  ## Ideally, we wouldn't have to do any of this, but the channels are not
  ## properly aligned.  We don't need anything too fancy, expand by 10 and
  ## crop the extra again is enough.  After all, this issue is only on the
  ## DAPI channel and that is only used to make nucleus mask.
  extra_size = [rows(dapi)+10 columns(dapi)+10];
  for f = size (dapi, 4)
    ## imresize should handle ND images but it doesn't...
    dapi(:,:,:,f) = imresize (dapi(:,:,:,f), extra_size)(6:end-5,6:end-5);
  endfor
endfunction


## Compute 3D nucleus mask from the DAPI channel.
function dapi_mask = get_dapi_mask (dapi)
  sigma = 2;
  g = fspecial ("gaussian", 2 * ceil (2*sigma) +1, sigma);
  dapi = uint16 (convn (dapi, repmat (g, [1 1 1 3]), "same"));

  dapi_mask = im2bw (dapi, graythresh (dapi(:)));
  dapi_mask = imclose (dapi_mask, strel ("disk", 2, 0));
  dapi_mask = bwfill (dapi_mask, "holes", 8);
  ## Reshape because bwfill only works in 2D
  dapi_mask = reshape (dapi_mask, size (dapi));

  dapi_mask = bwareaopen (dapi_mask, 1000, 8);

  ## Remove cells touching the borders since they are "incomplete" datasets.
  dapi_mask = imclearborder (dapi_mask, 8);
endfunction

## Save composite (2 colour) Z-stack tiff for ImageJ with labelled images.
##
## We only want this to make sure we got the nucleus mask right in 3D.
##
## The saved image will open in ImageJ as a composite image where each
## object in the mask appears labelled with a different colour.  The
## grayscale intensity values are adjusted for better contrast and the
## image is saved as 8-bit.
##
##    fpath (char[]) - filepath for image to be created
##    dapi (int[]) - grayscale image of size MxNx1xK
##    mask (bool[]) - mask of size MxNx1xK
function write_nucleus_mask_log (fpath, dapi, mask)
  dapi -= min (dapi(:));
  dapi = cast (double (dapi) * (255 / max (double (dapi(:)))), "uint8");
  label = bwlabeln (mask);
  im_log = cat (3, dapi, uint8 (label));
  im_log_size = size (im_log);
  im_log = reshape (im_log, [im_log_size(1:2) 1 im_log_size(3)*im_log_size(4)]);
  imwrite (im_log, fpath);
  ## We are using java objects so we need to do garbage collection ourselves.
  unwind_protect
    imp = javaObject ("ij.ImagePlus", make_absolute_filename (fpath));
    cim = javaObject ("ij.CompositeImage", imp);
    cim.setDimensions (2, cim.getNSlices () / 2, 1);

    grays_lut = im2uint8 (gray (256));
    grays_lut = javaObject ("ij.process.LUT", grays_lut(:,1), grays_lut(:,2),
                                              grays_lut(:,3));

    ## Seems like we can't access the actual glasbey lut from ImageJ
    ## library, so we recreate it here, at least in part which seems
    ## to be enough for us.
    mod_glasbey_lut = repmat (uint8 (255), 256, 3);
    mod_glasbey_lut(1:25,:) = [  0     0     0
                               255     0     0
                                 0   255     0
                                 0     0    51
                               255     0   182
                                 0    83     0
                               255   211     0
                                 0   159   255
                               154    77    66
                                 0   255   190
                               120    63   193
                                31   150   152
                               255   172   253
                               177   204   113
                               241     8    92
                               254   143    66
                               221     0   255
                                32    26     1
                               114     0    85
                               118   108   149
                                2    173    36
                              200    255     0
                              136    108     0
                              255    183   159
                              133    133   103];
    mod_glasbey_lut = javaObject ("ij.process.LUT", mod_glasbey_lut(:,1),
                                                    mod_glasbey_lut(:,2),
                                                    mod_glasbey_lut(:,3));
    luts = javaArray ("ij.process.LUT", 2);
    luts(1) = grays_lut;
    luts(2) = mod_glasbey_lut;
    cim.setLuts (luts);
    cim.setDisplayMode (cim.COMPOSITE);

    saver = javaObject ("ij.io.FileSaver", cim);
    saver.saveAsTiff (make_absolute_filename (fpath));
  unwind_protect_cleanup
    clear variables;
    [~] = javamem ();
  end_unwind_protect
endfunction

## Rescale image values to use whole dynamic range of its class.
##
## Despite the file and data being 16-bits, cameras are actually limited
## by something else (for our case, camera is 14-bit).  This makes for
## misleading plots and analysis since most functions expect the whole
## range to be used.  But we also don't want to just stretch the values
## since that will be misleading too (for example, an histogram that goes
## to 65535 would be lying), so we convert to double in the [0 1] range.
function im = whole_range (im, bit_max)
  im = double (im) / double (bit_max);
endfunction

## Run checks on the validity of a cell for analysis.
##
## Input:
##    vals (float[]) - array of pixels to check.  Single channel, single cell.
##
## Output:
##    status (bool) - true if there is an issue with the data, false otherwise.
##    msg (char[]) - a message if status was true.
function [status, msg] = check_cell_values (vals)
  status = true;
  if (any (vals >= 1))
    msg = "channel is saturated";
  elseif (iqr (vals) < 0.05)
    msg = "channel iqr less than 0.05";
  else
    status = false;
    msg = "";
  endif
endfunction

## Display mask with current cell highlighted.
##
##    dapi_2d ([]) - grayscale with maximum Z projection of DAPI channel.
##    cell_dapi (int[]) - linear index for elements of the current cell in 3D.
##    size_3d (int[]) - size of the dapi channel before projection.
function imshow_current_nucleus_mask (dapi_2d, cell_dapi, size_3d)
  [r, c] = ind2sub (size_3d, cell_dapi);
  ind_2d = sub2ind (size (dapi_2d), r, c);
  dapi_2d(ind_2d) = getrangefromclass (dapi_2d)(end);
  imshow (dapi_2d);
endfunction

## Plot histogram of a channel for a single cell.
##
##    vals (float[]) - intensity values in the [0 1] range.
##    channel_name (char[])
function status = imhist_channel (vals, channel_name)
  imhist (vals);
  ylim ("auto");
  xlabel ([channel_name " raw intensity"]);
  [status, msg] = check_cell_values (vals);
  if (status)
    text ("string", msg, "units", "normalized", "position", [0.5 0.5],
          "HorizontalAlignment", "center", "VerticalAlignment", "middle");
  endif
endfunction


function main (argv)
  filenames = argv;

  ## Bit depth of the camera
  ##
  ## While the data in the file may be 16bit, the camera may save it as
  ## as something else. We need a correct value to check if we don't have
  ## saturated images (or we could check the number of pixels with the
  ## maximum value).
  cam_depth = 14;
  bit_max = (2.^cam_depth)-1;


  for file_idx = 1:numel (filenames)
    fpath = filenames{file_idx};
    [fdir, fname] = fileparts (fpath);
    mask_log_fpath = fullfile (fdir, [fname "-mask_log.tif"]);

    try
      [dapi, h2ax, h2b] = read_image (fpath);
    catch
      warning ("%s.  Skipping...", lasterr ());
    end_try_catch

    nucleus_mask = get_dapi_mask (dapi);
    write_nucleus_mask_log (mask_log_fpath, dapi, nucleus_mask);

    dapi_max_projection = whole_range (max (dapi, [], 4), bit_max);

    cc = bwconncomp (nucleus_mask);
    for idx = 1:cc.NumObjects
      pixels_idx = cc.PixelIdxList{idx};

      cell_h2ax = whole_range (h2ax(pixels_idx), bit_max);
      cell_h2b  = whole_range (h2b(pixels_idx), bit_max);
      cell_dapi = whole_range (dapi(pixels_idx), bit_max);

      clf ();
      subplot (2, 3, 1);
      imshow_current_nucleus_mask (dapi_max_projection, pixels_idx,
                                   size (dapi));

      subplot (2, 3, 2);
      status_h2b = imhist_channel (cell_h2b, "H2B");
      subplot (2, 3, 3);
      status_h2ax = imhist_channel (cell_h2ax, "H2AX");

      plot_log_fpath = fullfile (fdir, sprintf ("%s-cell-%i.png", fname, idx));

      print (plot_log_fpath, "-S1920,1080");

    endfor
  endfor

endfunction

main (argv ());
