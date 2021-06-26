Params ['_side'];
Private ['_highCommandGroups', '_destroy', '_vehicles'];

_highCommandGroups = [_side] call WFCO_FNC_getHighCommandGroups;
if(count _highCommandGroups > 0) then {
    {
        _destroy = units _x;
        _vehicles = [];
        {
            if !(isPlayer _x) then {
                if (vehicle _x != _x) then { _vehicles pushBackUnique (vehicle _x) };
                if (_x isKindOf 'Man') then {removeAllWeapons _x};
                deleteVehicle _x
            }
        } forEach _destroy;
        { _x setDammage 1 } forEach _vehicles;
        _x setVariable ["isHighCommandPurchased", false, true];
        deleteGroup _x;
    } forEach _highCommandGroups
}