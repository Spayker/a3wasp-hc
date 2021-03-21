/*
	Create units for static defence.
	 Parameters:
		- Side
		- Groups
		- Spawn positions
		- Teams
		- Defence
		- Move In Gunner immidietly or not
*/

params ["_side", "_unitTypes", "_position", "_group", "_dir", ["_special", "FORM"]];
private ["_position", "_sideID", "_group", "_unitTypes"];
_sideID = (_side) call WFCO_FNC_GetSideID;

_built = 0;
_builtveh = 0;

for '_i' from 0 to count(_unitTypes)-1 do {

	["INFORMATION", Format["Common_CreateUnitForstaticForResBases.sqf: [%1] will create a team template %2 at %3", _side, _unitTypes # _i,_position]] Call WFCO_FNC_LogContent;

	if((_unitTypes # _i) isKindOf "Man") then {
	    _westGroup = createGroup [west, false];
	    _unit = [_unitTypes # _i, _westGroup, _position, _sideID] Call WFCO_FNC_CreateUnit;
	    [_unit] joinSilent _group;

	    deleteGroup _westGroup;
        _built  = _built + 1;
        _unit allowFleeing 0; //--- Make the units brave.
	} else {
	    _position = [_position, 30] call WFCO_fnc_getEmptyPosition;
        if(_special == 'FLY') then {
            _position = [_position # 0, _position # 1, 40]
        } else {
            _position = [_position # 0, _position # 1, 0.5]
        };
        _westGroup = createGroup [west, true];
	    _vehicleArray = [_position, _dir, _unitTypes # _i, _westGroup] call bis_fnc_spawnvehicle;
        _vehicle = _vehicleArray # 0;
        _vehicle  spawn {_this allowDamage false; sleep 15; _this allowDamage true};
        [str _side,'UnitsCreated',1] Call WFCO_FNC_UpdateStatistics;
        {
            [_x, typeOf _x,_westGroup,_position,_sideID] spawn WFCO_FNC_InitManUnit;

            private _classLoadout = missionNamespace getVariable Format ['WF_%1ENGINEER', _side];

            _x setUnitLoadout _classLoadout;
            _x setUnitTrait ["Engineer",true];
            [str _side,'UnitsCreated',1] Call WFCO_FNC_UpdateStatistics;
            [_x] joinSilent _group
        } forEach crew _vehicle;

        _unitskin = -1;
        _type = typeOf _vehicle;
        _vehicleCoreArray = missionNamespace getVariable [_type, []];
        if((count _vehicleCoreArray) > 10) then { _unitskin = _vehicleCoreArray # 10 };
        [_vehicle, _sideID, false, true, true, _unitskin] call WFCO_FNC_InitVehicle;
        _vehicle allowCrewInImmobile true;
        _vehicle engineOn true;
        _group addVehicle _vehicle;
	};
};

if (_built > 0) then {[str _side,'UnitsCreated',_built] call WFCO_FNC_UpdateStatistics};

["INFORMATION", Format["Common_CreateUnitForstaticForResBases.sqf:  [%1] was activated witha total of [%3] units.", _side, _built]] Call WFCO_FNC_LogContent;