draw_sprite(battleBackground, 0, x, y);

//Draw units in depth order
var _unitWithCurrentTurn = unitTurnOrder[turn].id;
for(var i = 0; i < array_length(unitRenderOrder); i++)
{
	with (unitRenderOrder[i])
	{
		draw_self();	
	}
}

//Draw ui boxes
draw_sprite_stretched(sBox, 0, x+75, y+120, 245, 60);
draw_sprite_stretched(sBox, 0, x, y+120, 74, 60);