draw_sprite_stretched(sBox, 0, x, y, widthFull, heightFull);
draw_set_color(c_white);
draw_set_font(fnM5x7);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _desc = !(description == -1);
var_scrollPush = max(0, hover - (visibleOptionsMax-1));

for (l = 0; l < (visibleOptionsMax + _desc); l++)
{
	if (l >= array_length(options)) break;
	draw_set_color(c_white);
	if (l == 0) && (_desc)
	{
		draw_text(x + xmargin, y + ymargin, description);	
	}
	else
	{
		var _optionToShow = l - _desc + _scrollPush;
		var _str = options[_optionToShow][0];
	