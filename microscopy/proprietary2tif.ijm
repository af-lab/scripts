// Copyright (C) 2012 Carnë Draug <carandraug+dev@gmail.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.

macro "lsm2tif" {
  extension = ".lsm";
  file_dir  = getDirectory("Choose a Directory ");
  file_list = get_cleansed_file_list (file_dir, extension);
  if (lengthOf(file_list) == 1 && file_list[0] == 0) {
    exit("No file was found in the selected directory with extension " + extension);
  }
  setBatchMode ("true");
  for (file_i = 0; file_i < lengthOf(file_list); file_i++) {
    imageID = open_ID (file_list[file_i]);
    saveAs("Tiff", File.directory + File.nameWithoutExtension + ".tif");
    close_by_ID (imageID);
  }
}
