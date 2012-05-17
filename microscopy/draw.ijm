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

// Setting the global variables
var radius    = 20;         // radius of circle
var shape     = "circle"    // what do draw


// this macro simple draws an overlay showing the center of the image
macro "Draw center" {
  width     = getWidth ();
  height    = getHeight ();
  x_center  = width/2;
  y_center  = height/2;
  if (shape == "circle") {
    if (radius > width || radius > height) {
      exit ("radius for circle is larger than image size");
    }
    Overlay.drawEllipse (x_center - radius, y_center - radius, radius * 2, radius * 2);
    Overlay.show;
  } else {
    exit ("Unknown shape to draw");
  }
}
