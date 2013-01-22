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
## @deftypefn {Function File} {} imread_multipage (@var{filename})
## Read multipage TIFF image.
##
## The call to this function is the same as @code{imread}, the only difference
## is that by default loads all the pages in case of a multipage TIFF.
##
## This is the same as @code{imread (filename, 1:numel (imfinfo (filename)))}
##
## @end deftypefn

function [img, map, alpha] = imread_multipage (filename)
  ## FIXME the code only deals with tif files... should port the OMERO toolbox
  ## for Octave and drop this limitation
  [img, map, alpha] = imread (filename, 1:numel (imfinfo (filename)));
endfunction
