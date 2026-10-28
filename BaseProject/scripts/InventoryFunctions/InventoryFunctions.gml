/// Inventory system for Lost Souls.
/// The inventory is shared between map and battle and is limited to 8 item slots.

function InventoryMaxSlots()
{
    return 8;
}

function InventoryAdd(_itemKey, _amount = 1)
{
    if (!variable_global_exists("itemLibrary")) return false;
    if (!variable_struct_exists(global.itemLibrary, _itemKey)) return false;
    if (_amount <= 0) return false;

    // Stack with an existing item first.
    for (var i = 0; i < array_length(global.inventory); i++)
    {
        if (global.inventory[i].key == _itemKey)
        {
            global.inventory[i].amount += _amount;
            return true;
        }
    }

    // Add a new slot if there is room.
    if (array_length(global.inventory) >= InventoryMaxSlots()) return false;

    array_push(global.inventory,
    {
        key: _itemKey,
        item: global.itemLibrary[$ _itemKey],
        amount: _amount
    });

    return true;
}

function InventoryRemove(_itemKey, _amount = 1)
{
    if (_amount <= 0) return false;

    for (var i = 0; i < array_length(global.inventory); i++)
    {
        if (global.inventory[i].key == _itemKey)
        {
            if (global.inventory[i].amount < _amount) return false;

            global.inventory[i].amount -= _amount;

            if (global.inventory[i].amount <= 0)
            {
                global.inventory = array_delete(global.inventory, i, 1);
            }

            return true;
        }
    }

    return false;
}

function InventoryHas(_itemKey, _amount = 1)
{
    if (_amount <= 0) return true;

    for (var i = 0; i < array_length(global.inventory); i++)
    {
        if (global.inventory[i].key == _itemKey)
            return global.inventory[i].amount >= _amount;
    }

    return false;
}

function InventoryMakeAction(_inventoryIndex)
{
    if (_inventoryIndex < 0 || _inventoryIndex >= array_length(global.inventory)) return -1;

    var _entry = global.inventory[_inventoryIndex];
    var _item = _entry.item;

    return
    {
        name: _item.name,
        description: _item.description,
        subMenu: -1,
        targetRequired: _item.targetRequired,
        targetEnemyByDefault: _item.targetEnemyByDefault,
        targetAll: _item.targetAll,
        inventoryIndex: _inventoryIndex,
        // Bind the item slot index to the action struct. Referencing the local
        // variable directly from an anonymous function can resolve as a missing
        // struct member in GameMaker LTS 2026.
        func: method({ inventoryIndex: _inventoryIndex }, function(_user, _targets)
        {
            InventoryUse(_user, _targets, inventoryIndex);
        })
    };
}

function InventoryCanUse(_inventoryIndex, _target)
{
    if (_inventoryIndex < 0 || _inventoryIndex >= array_length(global.inventory)) return false;
    if (is_struct(_target))
    {
        if (_target.hp <= 0) return false;
    }
    else
    {
        if (!instance_exists(_target) || _target.hp <= 0) return false;
    }

    var _item = global.inventory[_inventoryIndex].item;
    if (variable_struct_exists(_item, "canUse")) return _item.canUse(_target);
    return true;
}

function InventoryUse(_user, _targets, _inventoryIndex)
{
    if (_inventoryIndex < 0 || _inventoryIndex >= array_length(global.inventory)) return false;
    if (!is_array(_targets) || array_length(_targets) <= 0) return false;

    var _entry = global.inventory[_inventoryIndex];
    if (_entry.amount <= 0) return false;

    var _validTarget = false;
    for (var i = 0; i < array_length(_targets); i++)
    {
        if (InventoryCanUse(_inventoryIndex, _targets[i]))
        {
            _validTarget = true;
            break;
        }
    }
    if (!_validTarget) return false;

    _entry.item.use(_user, _targets);
    InventoryRemove(_entry.key, 1);
    return true;
}

// Field inventory uses party data structs rather than battle-unit instances.
function InventoryUseOutsideBattle(_user, _inventoryIndex, _targetIndex)
{
    if (_inventoryIndex < 0 || _inventoryIndex >= array_length(global.inventory)) return false;
    if (_targetIndex < 0 || _targetIndex >= array_length(global.party)) return false;

    var _target = global.party[_targetIndex];
    if (!InventoryCanUse(_inventoryIndex, _target)) return false;

    var _entry = global.inventory[_inventoryIndex];
    var _key = _entry.key;
    var _item = _entry.item;

    // Field characters are structs; battle characters are instances. Use the
    // same item metadata in both modes, but update the correct kind of target.
    if (!variable_struct_exists(_item, "healAmount")) return false;

    var _before = _target.hp;
    _target.hp = clamp(_target.hp + _item.healAmount, 0, _target.hpMax);
    if (_target.hp <= _before) return false;

    global.party[_targetIndex] = _target;
    InventoryRemove(_key, 1);
    return true;
}

function InventoryGetMenuOptions(_user)
{
    var _options = [];
    if (!variable_global_exists("inventory") || !is_array(global.inventory)) global.inventory = [];
    if (!variable_global_exists("party") || !is_array(global.party)) global.party = [];

    for (var i = 0; i < array_length(global.inventory); i++)
    {
        var _entry = global.inventory[i];
        var _item = _entry.item;
        var _available = (_entry.amount > 0);

        // Healing items become unavailable when every living party member is full.
        // In battle, global.party is only the saved party data. The live HP values
        // are on oBattleUnitPC instances, so do not disable items based on stale field HP.
        if (_available && !instance_exists(oBattle) && variable_struct_exists(_item, "canUseAny"))
        {
            _available = _item.canUseAny();
        }

        array_push(_options,
        [
            _item.name + " x" + string(_entry.amount),
            MenuSelectItem,
            [_user, i],
            _available
        ]);
    }

    if (array_length(_options) == 0)
    {
        array_push(_options, ["Empty", -1, -1, false]);
    }

    array_push(_options, ["Back", MenuGoBack, -1, true]);
    return _options;
}

function MenuSelectItem(_user, _inventoryIndex)
{
    if (_inventoryIndex < 0 || _inventoryIndex >= array_length(global.inventory)) exit;

    // In battle, use the battle-unit instances and the normal target cursor.
    if (instance_exists(oBattle))
    {
        var _action = InventoryMakeAction(_inventoryIndex);
        with (oMenu) active = false;

        with (oBattle)
        {
            with (cursor)
            {
                active = true;
                activeAction = _action;
                targetAll = false;
                activeUser = _user;
                targetIndex = 0;
                targetSide = array_filter(oBattle.partyUnits, function(_element, _index)
                {
                    return instance_exists(_element) && _element.hp > 0;
                });

                if (array_length(targetSide) > 0) activeTarget = targetSide[targetIndex];
                else
                {
                    active = false;
                    with (oMenu) active = true;
                }
            }
        }
        exit;
    }

    // Outside battle, build a target menu from the persistent party data.
    with (oMenu) instance_destroy();

    var _targetOptions = [];
    for (var i = 0; i < array_length(global.party); i++)
    {
        var _member = global.party[i];
        var _canUse = InventoryCanUse(_inventoryIndex, _member);
        array_push(_targetOptions,
        [
            _member.name + "  HP " + string(_member.hp) + "/" + string(_member.hpMax),
            FieldInventorySelectTarget,
            [_user, _inventoryIndex, i],
            _canUse
        ]);
    }
    array_push(_targetOptions, ["Back", FieldInventoryBackToItems, [_user], true]);
    Menu(camera_get_view_x(view_camera[0]) + 24, camera_get_view_y(view_camera[0]) + 24, _targetOptions, "Use on whom?", 190, 100);
}

function FieldInventorySelectTarget(_user, _inventoryIndex, _targetIndex)
{
    InventoryUseOutsideBattle(_user, _inventoryIndex, _targetIndex);
    with (oMenu) instance_destroy();
}

function FieldInventoryBackToItems(_user)
{
    with (oMenu) instance_destroy();
    var _options = InventoryGetMenuOptions(_user);
    Menu(camera_get_view_x(view_camera[0]) + 24, camera_get_view_y(view_camera[0]) + 24, _options, "Inventory", 190, 100);
}
