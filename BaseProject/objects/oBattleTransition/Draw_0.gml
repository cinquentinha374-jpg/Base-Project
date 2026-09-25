var _camX = camera_get_view_x(view_camera[0]);
var _camY = camera_get_view_y(view_camera[0]);
var _w = camera_get_view_width(view_camera[0]);
var _h = camera_get_view_height(view_camera[0]);

if (mode == "enter")
{
    // Phase 1: sharp white impact flash.
    if (timer <= flashFrames)
    {
        var _flash = 1 - (timer / flashFrames);
        draw_set_alpha(_flash);
        draw_set_color(c_white);
        draw_rectangle(_camX, _camY, _camX + _w, _camY + _h, false);
        draw_set_alpha(1);
    }

    // Phase 2: black bars slam toward the center.
    var _barProgress = clamp((timer - flashFrames) / barFrames, 0, 1);
    var _ease = 1 - power(1 - _barProgress, 3);
    var _barHeight = (_h * 0.5) * _ease;

    draw_set_color(c_black);
    if (_barHeight > 0)
    {
        draw_rectangle(_camX, _camY, _camX + _w, _camY + _barHeight, false);
        draw_rectangle(_camX, _camY + _h - _barHeight, _camX + _w, _camY + _h, false);
    }

    // Impact lines.
    if (timer >= 10 && timer < totalFrames)
    {
        var _centerY = _camY + _h * 0.5;
        var _lineAlpha = 0.35 + 0.25 * sin(timer * 1.7);

        draw_set_alpha(_lineAlpha);
        draw_set_color(c_white);
        draw_rectangle(_camX, _centerY - 1, _camX + _w, _centerY + 1, false);

        for (var i = 0; i < 5; i++)
        {
            var _yy = _camY + ((_h / 6) * (i + 1));
            draw_rectangle(_camX, _yy, _camX + _w, _yy + 1, false);
        }
        draw_set_alpha(1);
    }

    // Final black cover just before battle takes over.
    if (timer >= totalFrames - 4)
    {
        var _cover = clamp((timer - (totalFrames - 4)) / 4, 0, 1);
        draw_set_alpha(_cover);
        draw_set_color(c_black);
        draw_rectangle(_camX, _camY, _camX + _w, _camY + _h, false);
        draw_set_alpha(1);
    }
}
else if (mode == "exit")
{
    // Close from top and bottom over the battle.
    var _closeProgress = clamp(timer / exitCloseFrames, 0, 1);
    var _closeEase = 1 - power(1 - _closeProgress, 3);
    var _barHeight = (_h * 0.5) * _closeEase;

    draw_set_color(c_black);
    draw_rectangle(_camX, _camY, _camX + _w, _camY + _barHeight, false);
    draw_rectangle(_camX, _camY + _h - _barHeight, _camX + _w, _camY + _h, false);

    // Full black hold while the battle is removed and the defeated enemy is cleared.
    if (timer >= exitCloseFrames)
    {
        draw_set_alpha(1);
        draw_set_color(c_black);
        draw_rectangle(_camX, _camY, _camX + _w, _camY + _h, false);
    }

    // Open the bars to reveal the map.
    if (timer >= exitCloseFrames + exitHoldFrames)
    {
        var _openTimer = timer - (exitCloseFrames + exitHoldFrames);
        var _openProgress = clamp(_openTimer / exitOpenFrames, 0, 1);
        var _openEase = 1 - power(1 - _openProgress, 3);
        var _openBarHeight = (_h * 0.5) * (1 - _openEase);

        draw_set_color(c_black);
        draw_rectangle(_camX, _camY, _camX + _w, _camY + _openBarHeight, false);
        draw_rectangle(_camX, _camY + _h - _openBarHeight, _camX + _w, _camY + _h, false);

        // A subtle white flash at the beginning of the reveal.
        if (_openTimer < 5)
        {
            var _flash = 0.12 * (1 - (_openTimer / 5));
            draw_set_alpha(_flash);
            draw_set_color(c_white);
            draw_rectangle(_camX, _camY, _camX + _w, _camY + _h, false);
            draw_set_alpha(1);
        }
    }
}

draw_set_alpha(1);
draw_set_color(c_white);
