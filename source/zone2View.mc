import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.UserProfile;
import Toybox.Application;
import Toybox.Attention;

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
    var current_zone;
    var hr_zones as Array<Number>;
    var hr_zone_start;
    var hr_zone_end;
    var screen_width;
    var screen_height;
    var hr_text_size;
    var hr_text_x_offset;
    var hr_text_color;
    var line_text_size;
    var line_text_visible;
    var background_color;
    var foreground_color;
    var use_rounded_boxes;
    var obscurity_flags;
    var time_since_last_vibration;
    var vibrate_above;
    var vibration_frequency;

    function initialize() {
        DataField.initialize();
        current_hr = 42.0f;
        n_boxes = 7;
        seconds_per_box = 7;
        box_values = [0, 0, 0, 0, 0, 0, 0];
        heart_rates = [0, 0, 0, 0, 0, 0, 0];
        current_count = 0;
        
        current_sport = UserProfile.getCurrentSport();
        hr_zones = UserProfile.getHeartRateZones(current_sport);

        foreground_color = Graphics.COLOR_PURPLE;
        time_since_last_vibration = 120;
    }

    function update_settings_from_properties() {
        obscurity_flags = DataField.getObscurityFlags();
        seconds_per_box = Properties.getValue("SecondsPerBox");
        n_boxes = Properties.getValue("NumberOfBoxes");
        use_rounded_boxes = Properties.getValue("RoundedBoxes");
        current_zone = Properties.getValue("ZoneNumber");
        vibrate_above = Properties.getValue("AlertAbove");
        vibration_frequency = Properties.getValue("AlertFrequency");


        var hr_zone_start_offset = (current_zone == 3) ? 5 : 3;
        hr_zone_start = hr_zones[current_zone - 1] - hr_zone_start_offset;
        hr_zone_end = hr_zones[current_zone];
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {

        update_settings_from_properties();
        
        if (heart_rates.size() != seconds_per_box) {
            heart_rates = new [seconds_per_box];
            for (var i = 0; i < seconds_per_box; i += 1) {
                heart_rates[i] = 0;
            }
        }
        if (box_values.size() != n_boxes) {
            box_values = new [n_boxes];
            for (var i = 0; i < n_boxes; i += 1) {
                box_values[i] = 0;
            }
        }

        View.setLayout(Rez.Layouts.MainLayout(dc));

        screen_width = dc.getWidth();
        screen_height = dc.getHeight();
        
        hr_text_size = get_hr_text_size(screen_width, screen_height);
        line_text_size = get_line_text_size(screen_width, screen_height);
        hr_text_x_offset = get_hr_text_offset(screen_width, screen_height);
        line_y_offset_above = 0.25 * screen_height;
        line_y_offset_below = 0.229167 * screen_height;

        xmin = 0;
        xmax = get_xmax(screen_width, screen_height);
        
        box_width = get_box_width(xmin, xmax, n_boxes);
        box_height = get_box_height(screen_height);
    }

    function compute(info as Activity.Info) as Void {

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
        var background = View.findDrawableById("Background") as Background;
        background.setColor(background_color);

        dc.setColor(Graphics.COLOR_WHITE, background_color);
        View.onUpdate(dc);

        draw_dashed_line(dc, 0, line_y_offset_above, xmax, 1, foreground_color);
        draw_dashed_line(dc, 0, screen_height - line_y_offset_below, xmax, 1, foreground_color);
        if (line_text_visible) {
            dc.drawText(xmax + 3, line_y_offset_above - 10, line_text_size, hr_zone_end.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(xmax + 3, screen_height - line_y_offset_below - 10, line_text_size, hr_zone_start.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
        }

        dc.setColor(hr_text_color, background_color);
        dc.drawText(xmax + hr_text_x_offset, screen_height/2 - 15, hr_text_size, current_hr.format("%.0f"), Graphics.TEXT_JUSTIFY_CENTER);

        var k = (line_y_offset_above - (screen_height - line_y_offset_below)) / (hr_zone_end - hr_zone_start);

        for (var i = 0; i < n_boxes; i += 1) {
            var box_hr = box_values[i];
            var x_i = i * (box_width + 1);
            var y_i = screen_height - line_y_offset_below - (hr_zone_start - box_hr)*k - box_height / 2;
            var color = get_box_color(box_hr);
            
            if (use_rounded_boxes) {
                draw_rounded_rect(dc, x_i, y_i, box_width, box_height, 1, color);
            } else {
                draw_rect(dc, x_i, y_i, box_width, box_height, color);
            }
        }

        if (should_vibrate()) {
            vibrate();
        }
        if (time_since_last_vibration < vibration_frequency) {
            time_since_last_vibration += 1;
        }
    }

    function should_vibrate() {

        if (vibrate_above) {
            if (box_values[box_values.size()-1] >= hr_zone_end and time_since_last_vibration >= vibration_frequency) {
                return true;
            }
        }

        return false;
    }

    function vibrate() {
        if (Attention has :vibrate) {
            var vibrations = [
                new Attention.VibeProfile(80, 150),
                new Attention.VibeProfile(0, 75),
                new Attention.VibeProfile(75, 75),
                new Attention.VibeProfile(0, 75),
                new Attention.VibeProfile(75, 75),
            ];
            Attention.vibrate(vibrations);
            time_since_last_vibration = 0;
        }
    }

    function get_box_color(hr) {
        var color = Graphics.COLOR_RED;
            
        if (hr > hr_zone_end + 1) {
            color = Graphics.COLOR_RED;
        } else if (hr > hr_zone_end - 2) {
            color = Graphics.COLOR_ORANGE; // "0xff781f"; // orange
        } else if (hr > hr_zone_end - 4) {
            color = Graphics.COLOR_GREEN; // lime
        } else if (hr >= hr_zone_start) {
            color = Graphics.COLOR_DK_GREEN;
        } else if (hr >= hr_zone_start - 3) {
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

    function get_hr_text_size(screen_width, screen_height) as Graphics.FontType {
        var hr_text_size_enum = Properties.getValue("HrTextSize");
        var hr_text_size = Graphics.FONT_MEDIUM;

        if (hr_text_size_enum == 0) {  // "Smaller"
            hr_text_size = Graphics.FONT_SMALL;
        } else if (hr_text_size_enum == 2) {  // "Larger"
            hr_text_size =  Graphics.FONT_LARGE;
        }

        if (screen_height < 120) {
            hr_text_size = Graphics.FONT_SMALL;
        }
        if (screen_width < 190) {
            hr_text_size = Graphics.FONT_XTINY;
        }

        return hr_text_size;
    }

    function get_line_text_size(screen_width, screen_height) as Graphics.FontType {
        var line_text_size_enum = Properties.getValue("LineTextSize");
        var line_text_size = Graphics.FONT_XTINY;
        if (line_text_size_enum == "Larger") {
            line_text_size = Graphics.FONT_SMALL;
        }

        line_text_visible = true;
        if (screen_height < 120) {
            line_text_visible = false;
        }
        if (screen_width < 190) {
            line_text_visible = false;
        }

        return line_text_size;
    }

    function get_hr_text_offset(screen_width, screen_height) {
        var hr_text_x_offset = 25;
        if (screen_width < 190) {
            hr_text_x_offset = 15;
        }

        return hr_text_x_offset;
    }

    function get_xmax(screen_width, screen_height) {
        var xmax = 0.7708 * screen_width;
        if (screen_height < 120) {
            if (obscurity_flags == (OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_RIGHT) or obscurity_flags == (OBSCURE_BOTTOM | OBSCURE_LEFT | OBSCURE_RIGHT)) {
                xmax = 0.6708 * screen_width;
            }
        }
        return xmax;
    }

    function get_box_width(xmin, xmax, n_boxes) {
        return (xmax - xmin) / n_boxes - 1;
    }

    function get_box_height(screen_height) {
        return Properties.getValue("BoxHeight") * screen_height;
    }

    function print(str) as Void {
        System.println(str);
    }
}
