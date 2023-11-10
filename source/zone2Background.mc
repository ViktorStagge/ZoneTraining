import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;

class Background extends WatchUi.Drawable {

    hidden var mColor as ColorValue;

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);

        mColor = Graphics.COLOR_PURPLE;
    }

    function setColor(color as ColorValue) as Void {
        mColor = Graphics.COLOR_PURPLE;
    }

    function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();
    }

}
