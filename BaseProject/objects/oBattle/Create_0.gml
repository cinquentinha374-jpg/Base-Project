// Remember the player position and the map enemy that started this encounter.
// The map is deactivated during battle, so these instances remain available.
returnX = creator.x;
returnY = creator.y;
defeatedEnemy = encounterEnemy;

// Keep the map instances active during battle. The battle scene draws over the map,
// while the player is frozen by global.inBattleTransition. This lets us return
// to the same map without losing or deactivating the field instances.

units = [];
enemyUnits = [];
partyUnits = [];
turn = 0;
turnCount = 0;
roundCount = 0;
battleWaitTimeFrames = 30;
battleWaitTimeRemaining = 0;
battleText = "";
currentUser = noone;
currentAction = -1;
currentTargets = noone;
unitTurnOrder = [];
unitRenderOrder = [];

//Make targetting cursor
cursor = 
{
	activeUser : noone,
	activeTarget : noone,
	activeAction : -1,
	targetSide : -1,
	targetIndex	: 0,
	targetAll : false,
	confirmDelay : 0,
	active : false
};


//Make enemies
for (var i = 0; i < array_length(enemies); i++)
{
	enemyUnits[i] = instance_create_depth(x+250+(i*10), y+68+(i*20), depth-10, oBattleUnitEnemy, enemies[i]);
	array_push(units, enemyUnits[i]);
}

//Make enemies
for (var i = 0; i < array_length(global.party); i++)
{
	partyUnits[i] = instance_create_depth(x+70+(i*10), y+68+(i*15), depth-10, oBattleUnitPC, global.party[i]);
	array_push(units, partyUnits[i]);
}

//Shuffle turn order
unitTurnOrder = array_shuffle(units);

//Get render order
RefreshRenderOrder = function ()
{
		unitRenderOrder = [];
		array_copy(unitRenderOrder, 0, units, 0, array_length(units));
		array_sort(unitRenderOrder, function(_1,_2)
		{
			return _1.y - _2.y;	
		});
}
RefreshRenderOrder();


function BattleStateSelectAction()
{
	if(!instance_exists(oMenu))
	{
		//Get current unit
		var _unit = unitTurnOrder[turn];
	
		//Is the unit dead or unable to act?
		if (!instance_exists(_unit)) || (_unit.hp <= 0)
		{
			battleState = BattleStateVictoryCheck;
			exit;
		}
	
		//Select an action to perform
		//BeginAction(_unit.id, global.actionLibrary.attack, _unit.id);
	
		//If unit is player controlle
		if (_unit.object_index == oBattleUnitPC)
		{
			//Compile the action menu
			var _menuOptions = [];
			var _subMenus = {};
			
			var _actionList = _unit.actions;
			
			for (var i =  0; i < array_length(_actionList); i++)
			{
				var _action = _actionList[i];
				var _available = true;
				var _nameAndCount = _action.name;
				if(_action.subMenu == -1)
				{
					array_push(_menuOptions, [_nameAndCount, MenuSelectAction, [_unit, _action], _available]);
				}
				else
				{
					//create or add to submenu
					if (is_undefined(_subMenus [$ _action.subMenu]))
					{
						variable_struct_set(_subMenus, _action.subMenu, [[_nameAndCount, MenuSelectAction, [_unit, _action], _available]]);
					}
					else
					{
						array_push(_subMenus [$ _action.subMenu], [_nameAndCount, MenuSelectAction, [_unit, _action], _available]);
					}
				}
			}
			
			//turn sub menus into an array
			var _subMenusArray = variable_struct_get_names(_subMenus);
			for (var i = 0; i < array_length(_subMenusArray); i++)
			{
				//sort submenu if needed
				//(here)
					
				//add back option at the end of each submenu
				array_push(_subMenus [$ _subMenusArray[i]], ["Back", MenuGoBack, -1, true]);
				//add submenu into main menu
				array_push(_menuOptions, [_subMenusArray[i], SubMenu, [_subMenus[$ _subMenusArray[i]]], true]);
			}
			
			
			Menu(x+10, y+110, _menuOptions, , 74, 60);
					
		}
		else
		{
			var _enemyAction = _unit.AIscript();
			if (_enemyAction != -1) BeginAction(_unit.id, _enemyAction[0], _enemyAction[1]);
		}
	}
}

function BeginAction(_user, _action, _targets)
{
	currentUser = _user;
	currentAction = _action;
	currentTargets = _targets;
	battleText = string_ext(_action.description, [_user.name]);
	if (!is_array(currentTargets)) currentTargets = [currentTargets];
	battleWaitTimeRemaining = battleWaitTimeFrames;
	with(_user)
	{
		acting = true;
		//Play user animation if is defined for that action, and that user
		if (!is_undefined(_action[$ "userAnimation"])) && (!is_undefined(_user.sprites[$ _action.userAnimation]))
		{
			sprite_index = sprites[$ _action.userAnimation];
			image_index = 0;
		}
	}
	battleState = BattleStatePerformAction;
}

function BattleStatePerformAction()
{
	//If animation etc is still playing
	if (currentUser.acting)
	{
		//When it ends, perform action effect if it exists
		if(currentUser.image_index >= currentUser.image_number -1)
		{
			with(currentUser)
			{
				sprite_index = sprites.idle;
				image_index = 0;
				acting = false;
			}
			if (variable_struct_exists(currentAction, "effectSprite"))
			{
				if (currentAction.effectOnTarget == MODE.ALWAYS) || ( (currentAction.effectOnTarget == MODE.VARIES) && (array_length(currentTargets) <= 1) )
				{
					for (var i = 0; i < array_length(currentTargets); i++)
					{
						instance_create_depth(currentTargets[i].x, currentTargets[i].y, currentTargets[i].depth-1, oBattleEffect,{sprite_index : currentAction.effectSprite});	
					}
				}
				else //Play it at 0, 0
				{
					var _effectSprite = currentAction._effectSprite
					if (variable_struct_exists(currentAction, "affectSpriteNoTarget")) _effectSprite = currentAction.effectSpriteNoTarget;
					instance_create_depth(x, y, depth-100, oBattleEffect, {sprite_index : _effectSprite});
				}
			}
			currentAction.func(currentUser, currentTargets);
		}
	}
	else //wait for delay and then end the turn
	{
		if (!instance_exists(oBattleEffect))
		{
			battleWaitTimeRemaining--
			if (battleWaitTimeRemaining == 0)
			{
				battleState = BattleStateVictoryCheck;	
			}
		}
	}
			
}

function BattleStateVictoryCheck()
{
    // Check whether at least one enemy is still alive.
    var _enemyAlive = false;

    for (var i = 0; i < array_length(enemyUnits); i++)
    {
        var _enemy = enemyUnits[i];

        if (instance_exists(_enemy) && _enemy.hp > 0)
        {
            _enemyAlive = true;
            break;
        }
    }

    if (!_enemyAlive)
    {
        battleState = BattleStateVictory;
        exit;
    }

    battleState = BattleStateTurnProgession;
}

function BattleStateVictory()
{
    // Start the return transition while keeping the map underneath intact.
    // The transition covers the battle, cleans up the defeated enemy at full black,
    // then reveals the map again.
    if (!instance_exists(oBattleTransition))
    {
        instance_create_depth
        (
            camera_get_view_x(view_camera[0]),
            camera_get_view_y(view_camera[0]),
            -100000,
            oBattleTransition,
            {
                mode: "exit",
                creator: creator,
                defeatedEnemy: defeatedEnemy,
                returnX: returnX,
                returnY: returnY
            }
        );
    }

    // Close any battle menu.
    if (instance_exists(oMenu))
    {
        with (oMenu) instance_destroy();
    }

    // Remove battle-only units and effects.
    for (var i = 0; i < array_length(units); i++)
    {
        if (instance_exists(units[i]))
        {
            with (units[i]) instance_destroy();
        }
    }

    with (oBattleEffect) instance_destroy();
    with (oBattleFloatingText) instance_destroy();

    // The map enemy and player position are handled by oBattleTransition
    // while the screen is fully black.
    global.inBattleTransition = true;

    // End this battle controller.
    instance_destroy();
}

function BattleStateTurnProgession()
{
	battleText = "";
	turnCount++;
	turn++;
	//Loop turns
	if (turn > array_length(unitTurnOrder) - 1)
	{
		turn = 0;
		roundCount++;
	}
	battleState = BattleStateSelectAction;
}

battleState = BattleStateSelectAction;






