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
pkg load imagej;

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
endfunction

function write_nucleus_mask_log (fpath, dapi, mask)
  ## We only want this to make sure we got the nucleus mask right in 3D.
  ## So we just convert to uin8 and adjust intensity of the DAPI.  We
  ## then open the image in ImageJ to save the second channel as labeled.
  ## Convert to uint8 for save as 
  dapi -= min (dapi(:));
  dapi = cast (double (dapi) * (255 / max (double (dapi(:)))), "uint8");
  label = bwlabeln (mask);
  im_log = cat (3, dapi, uint8 (label));
  im_log_size = size (im_log);
  im_log = reshape (im_log, [im_log_size(1:2) 1 im_log_size(3)*im_log_size(4)]);
  imwrite (im_log, fpath);
  ## We are using java objects, we need to do garbage collection ourselves.
  unwind_protect
    imp = javaObject ("ij.ImagePlus", make_absolute_filename (fpath));
    cim = javaObject ("ij.CompositeImage", imp);
    cim.setDimensions (2, cim.getNSlices () / 2, 1);

    grays_lut = im2uint8 (gray (256));
    grays_lut = javaObject ("ij.process.LUT", grays_lut(:,1), grays_lut(:,2),
                                              grays_lut(:,3));

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

function main (argv)
  filenames = argv;

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
  endfor

endfunction

main (argv ());
