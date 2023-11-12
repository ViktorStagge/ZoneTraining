import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;

class Background extends WatchUi.Drawable {

    hidden var background_color as ColorValue;

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);

        background_color = Graphics.COLOR_WHITE;
    }

    function setColor(color as ColorValue) as Void {
        background_color = color;
    }

    function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_TRANSPARENT, background_color);
        dc.clear();
    }

}
