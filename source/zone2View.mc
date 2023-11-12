import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.UserProfile;

var default_foreground = Graphics.COLOR_PURPLE;


class zone2View extends WatchUi.DataField {

    hidden var current_hr as Numeric;
    var xmin;
    var xmax;
    var box_width;
    var box_height;
    var box_values as Array;
    var n_boxes;
    var seconds_per_box;
    var line_y_offset_above;
    var line_y_offset_below;
    var heart_rates as Array<Number>;
    var current_count as Number;
    var current_sport as UserProfile.SportHrZone;
    var hr_zones as Array<Number>;
    var hr_zone2_start as Number;
    var hr_zone2_end as Number;
    var screen_width;
    var screen_height;
    var hr_text_size;
    var hr_text_x_offset;
    var line_text_size;
    var line_text_visible;
    var background_color;
    var foreground_color;
    var hr_text_color;

    function initialize() {
        DataField.initialize();
        current_hr = 42.0f;
        n_boxes = 7;
        seconds_per_box = 7;
        box_values = [0, 0, 0, 0, 0, 0, 0, 0];
        heart_rates = [0, 0, 0, 0, 0, 0, 0];
        current_count = 0;
        
        current_sport = UserProfile.getCurrentSport();
        hr_zones = UserProfile.getHeartRateZones(current_sport);
        hr_zone2_start = hr_zones[2] - 4;
        hr_zone2_end = hr_zones[3] + 1;

        foreground_color = Graphics.COLOR_PURPLE;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        //var obscurityFlags = DataField.getObscurityFlags();

        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label") as Text;
        labelView.locY = labelView.locY - 16;
        var valueView = View.findDrawableById("value") as Text;
        valueView.locY = valueView.locY + 7;

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);

        screen_width = dc.getWidth();
        screen_height = dc.getHeight();
        
        xmin = 0;
        xmax = 0.7708 * screen_width;
        
        box_width = (xmax - xmin) / n_boxes - 1;
        //box_height = 0.100 * screen_height;
        box_height = 1.1 * box_width;
        if (box_height > 0.125 * screen_height) {
            box_height = 0.125 * screen_height;
        }

        line_y_offset_above = 0.25 * screen_height;
        line_y_offset_below = 0.229167 * screen_height;

        hr_text_size = Graphics.FONT_MEDIUM;
        hr_text_x_offset = 25;
        line_text_size = Graphics.FONT_XTINY;
        line_text_visible = true;
        if (screen_height < 120) {
            hr_text_size = Graphics.FONT_SMALL;
            line_text_visible = false;
        }
        if (screen_width < 190) {
            hr_text_size = Graphics.FONT_XTINY;
            hr_text_x_offset = 15;
            line_text_visible = false;
        }

        background_color = getBackgroundColor();
    }

    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if(info has :currentHeartRate){
            if(info.currentHeartRate != null){
                current_hr = info.currentHeartRate as Number;

                for (var i = 0; i < seconds_per_box - 1; i += 1) {
                    heart_rates[i] = heart_rates[i+1];
                }
                heart_rates[seconds_per_box-1] = current_hr;

                if (current_count % seconds_per_box == 0) {
                    for (var i = 0; i < n_boxes - 1; i += 1) {
                        box_values[i] = box_values[i+1];
                    }
                    box_values[n_boxes-1] = mean(heart_rates);
                }

                current_count += 1;
            } else {
                current_hr = 0.0f;
            }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        background_color = getBackgroundColor();
        hr_text_color = (background_color == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(background_color);

        var value = View.findDrawableById("value") as Text;
        value.setColor(default_foreground);
        value.setText("");


        dc.setColor(Graphics.COLOR_WHITE, background_color);  // foreground, background
        View.onUpdate(dc);
        //dc.clear();

        draw_dashed_line(dc, 0, line_y_offset_above, xmax, 1, default_foreground);
        draw_dashed_line(dc, 0, screen_height - line_y_offset_below, xmax, 1, default_foreground);

        if (line_text_visible) {
            dc.drawText(xmax + 3, line_y_offset_above - 10, line_text_size, hr_zone2_end.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(xmax + 3, screen_height - line_y_offset_below - 10, line_text_size, hr_zone2_start.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(hr_text_color, background_color);
        dc.drawText(xmax + hr_text_x_offset, screen_height/2 - 15, hr_text_size, current_hr.format("%.0f"), Graphics.TEXT_JUSTIFY_CENTER);

        var k = (line_y_offset_above - (screen_height - line_y_offset_below)) / (hr_zone2_end - hr_zone2_start);

        for (var i = 0; i < n_boxes; i += 1) {
            var box_hr = box_values[i];
            var x_i = i * (box_width + 1);
            var y_i = screen_height - line_y_offset_below - (hr_zone2_start - box_hr)*k - box_height / 2;
            var color = get_box_color(box_hr);

            draw_rounded_rect(dc, x_i, y_i, box_width, box_height, 1, color);
        }

        var x_i = xmax;
        var y_i = screen_height - line_y_offset_below - (hr_zone2_start - current_hr)*k - 2;
        var color = get_box_color(current_hr);
        draw_rect(dc, x_i, y_i, 4, 4, color);
    }

    function get_box_color(hr) {
        var color = Graphics.COLOR_RED;
            
        if (hr > hr_zone2_end + 1) {
            color = Graphics.COLOR_RED;
        } else if (hr > hr_zone2_end - 2) {
            color = Graphics.COLOR_ORANGE; // "0xff781f"; // orange
        } else if (hr > hr_zone2_end - 4) {
            color = Graphics.COLOR_GREEN; // lime
        } else if (hr >= hr_zone2_start) {
            color = Graphics.COLOR_DK_GREEN;
        } else if (hr >= hr_zone2_start - 3) {
            color = Graphics.COLOR_GREEN; // "0xaef359"; // lime
        } else {
            color = Graphics.COLOR_RED;
        }

        return color;
    }

    function draw_dashed_line(dc, x, y, width, height, color) {
        var dash_length = 9;
        var gap_length = 3;

        var line_dimension = 0;
        var distance = width;
        if (height > width) {
            line_dimension = 1;
            distance = height;
        }
        
        var line_length_offset = 0;
        for (var z = 0;  z < distance; z += dash_length + gap_length) {
            if (z + dash_length > distance) {
                line_length_offset = (z + dash_length) - distance;
            }

            if (line_dimension == 0) {
                draw_rect(dc, x+z, y, dash_length - line_length_offset, height, color);
            }
            if (line_dimension == 1) {
                draw_rect(dc, x, y+z, width, dash_length - line_length_offset, color);
            }
        }
    }

    function draw_rect(dc, x, y, width, height, color) {
        dc.setColor(color, background_color);
        dc.fillRectangle(x, y, width, height);
        dc.setColor(default_foreground, background_color);
    }

    function draw_rounded_rect(dc, x, y, width, height, radius, color) {
        dc.setColor(color, background_color);
        dc.fillRoundedRectangle(x, y, width, height, radius);
        dc.setColor(default_foreground, background_color);
    }

    function get_2d_array(x_dim, y_dim, fill_value) {
        
        var array = new Array<Array>[x_dim];
        for (var i = 0; i < x_dim; i += 1) {
            array[i] = new [y_dim];
        }

        if (fill_value != null) {
            for (var i = 0; i < x_dim; i += 1) {
                for (var j = 0; j < y_dim; j += 1) {
                    array[i][j] = fill_value;
                }
            }
        }

        return array;
    }

    function mean(array as Array) {
        if (array.size() == 0) {
            return null;
        }

        var sum = 0;
        var avg = 0;
        for (var i = 0; i < array.size(); i += 1) {
            sum += array[i];
        }
        avg = sum / array.size();
        return avg;
    }

    function print(str) as Void {
        System.println(str);
    }
}


