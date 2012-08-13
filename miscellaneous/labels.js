// Copyright (C) 2010 Carnë Draug <carandraug+dev@gmail.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.

// this function goes through all label spaces and replaces all $ followed by
// the specified number, by an autoincremented number. The argument 'number'
// is used to locate the start value for replacement
function replace_variable(number){
  var_start   = document.getElementById("variable"+number+"start").value;
  var_finder  = new RegExp("\\$"+number+"","g");

  for (col = 1; col <= col_limit; col++) {
    for (row = 1; row <= row_limit; row++) {
      label = document.getElementById(row+"-"+col).value;
      if (label.search(var_finder) != -1) {
        label = label.replace(var_finder, var_start);
        var_start++;
        document.getElementById(row+"-"+col).value = label;
      }
    }
  }
}

// this function copies and deletes text around the textareas. The arguments
// set the coordinates of the textarea to be affected. When they have a value
// of 'x', all rows or collumns, will be affected.
function text_manipulator(col,row){
  //work_mode[0] is delete -- replace the value by an empty string
  if (document.calculator.work_mode[0].checked){
    if (col == "x" && row == "x") {
      for (row = 1; row <= col_limit; row++) {
        for (col = 1; col <= row_limit; col++) {
          document.getElementById(col+"-"+row).value = "";
        }
      }
    }
    else if (col == "x" && row != "x") {
      for (col = 1; col <= row_limit; col++) {
        document.getElementById(col+"-"+row).value = "";
      }
    }
    else if (col != "x" && row == "x") {
      for (row = 1; row <= col_limit; row++) {
        document.getElementById(col+"-"+row).value = "";
      }
    }
    else {
      document.getElementById(col+"-"+row).value = "";
    }
  }
  //work_mode[1] is copy -- replace 'selected_text' value by the selected textarea
  else if (document.calculator.work_mode[1].checked){
    if (col == "x" && row == "x") {
      alert ("You can only copy the text from a single cell. If you think that would be really handy, feel free to change the script and submit it to David.");
    }
    else if (col == "x" && row != "x") {
      alert ("You can only copy the text from a single cell. If you think that would be really handy, feel free to change the script and submit it to David.");
    }
    else if (col != "x" && row == "x") {
      alert ("You can only copy the text from a single cell. If you think that would be really handy, feel free to change the script and submit it to David.");
    }
    else {
      document.getElementById("selected_text").value = document.getElementById(col+"-"+row).value;
    }
  }
  //work_mode[2] is paste -- replaces the selected textarea value by the value of 'selected_text'
  else if (document.calculator.work_mode[2].checked){
    if (col == "x" && row == "x") {
      for (row = 1; row <= col_limit; row++) {
        for (col = 1; col <= row_limit; col++) {
          document.getElementById(col+"-"+row).value = document.getElementById("selected_text").value;
        }
      }
    }
    else if (col == "x" && row != "x") {
      for (col = 1; col <= row_limit; col++) {
        document.getElementById(col+"-"+row).value = document.getElementById("selected_text").value;
      }
    }
    else if (col != "x" && row == "x") {
      for (row = 1; row <= col_limit; row++) {
        document.getElementById(col+"-"+row).value = document.getElementById("selected_text").value;
      }
    }
    else {
      document.getElementById(col+"-"+row).value = document.getElementById("selected_text").value;
    }
  }
  //work_mode value unexpected
  else {
    alert("wtf have you done?");
  }
}

function set_color(red, green, blue) {
  document.getElementById("rrr").value = red;
  document.getElementById("ggg").value = green;
  document.getElementById("bbb").value = blue;
  check_color ('rrr');
  check_color ('ggg');
  check_color ('bbb');
}

function check_color(id) {
  field = document.getElementById(id);
  if(isNaN(field.value) || field.value > 255 || field.value < 0){
    field.style.backgroundColor  = bad_color;
    return false;
  }else{
    field.style.backgroundColor  = good_color;
    return true;
  }
}

function check_submission() {
  r = check_color(document.getElementById('rrr'));
  g = check_color(document.getElementById('ggg'));
  b = check_color(document.getElementById('bbb'));
  if (r && g && b) {
    return true;
  } else {
    alert("RGB values are incorrect.\nAcceptable values are between 0 and 255")
    return false;
  }
}
