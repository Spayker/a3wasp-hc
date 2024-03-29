params ["_list", "_position", "_side", "_sideID", "_lockVehicles", "_group", ["_global", true]];
private ['_sideID','_type','_unit','_units','_vehicle','_vehicles'];

_units = [];
_vehicles = [];

if (_list isEqualType "") then {_list = [_list]};

{
	if (_x isKindOf 'Man') then {
		_position = [_position, 2, 15, 5, 0, 20, 0] call BIS_fnc_findSafePos;

		_unit = [_x,_group,_position,_sideID] Call WFCO_FNC_CreateUnit;

		_unit disableAI "RADIOPROTOCOL";
		if(isDedicated) then {
            _unit enableSimulationGlobal false
		} else {
            _unit enableSimulation false
        };

		_units pushBack _unit;
		sleep 0.5;
    } else {
		_height = .5;
		_startHeight = 150 - random(100);
		
		if(_x isKindOf 'Air') then {
            _height = 250;
            _startHeight = 250;
		};

        _safePos = [_position, 200] call WFCO_fnc_getEmptyPosition;
        if(_x isKindOf 'Ship') then { _safePos = [_position, 2, 75, 5, 2, 0, 1] call BIS_fnc_findSafePos };
        _vehicle = [_x, [_safePos # 0, _safePos # 1, _height], _sideID, 0, _lockVehicles, true, _global] Call WFCO_FNC_CreateVehicle;
        if(_x isKindOf 'Air') then {
            _vehicle lock true
        } else {
            _vehicle setVectorUp surfaceNormal position _vehicle
        };

        _group reveal _vehicle;
        createVehicleCrew _vehicle;
        if(isDedicated) then {
            _vehicle enableSimulationGlobal false;
		} else {
            _vehicle enableSimulation false;
		};

        _vehicle removeAllEventHandlers "HandleDamage";
        _vehicleHandleDamageEventHandler = _vehicle addEventHandler ["HandleDamage", {false}];
        [_vehicle, _vehicleHandleDamageEventHandler] spawn {
            params["_vehicle", "_eventHandler"];
            _vehicle allowDamage false;
            _vehicle removeEventHandler ["HandleDamage", _eventHandler];
            _vehicle allowDamage true
        };

		{
            [_x, typeOf _x,_group,_position,_sideID] Call WFCO_FNC_InitManUnit;
            [_x] joinSilent _group;
            private _classLoadout = missionNamespace getVariable Format ['WF_%1WHEELEDCREW',_side];
            if(_vehicle isKindOf "Tank") then {
                _classLoadout = missionNamespace getVariable Format ['WF_%1TRACKEDCREW',_side];
            };
            if(_vehicle isKindOf "Air") then {
                _classLoadout = missionNamespace getVariable Format ['WF_%1PILOT',_side];
            };
            _x setUnitLoadout _classLoadout;
            _x setUnitTrait ["Engineer",true];
            _x disableAI "RADIOPROTOCOL";
        } forEach crew _vehicle;

        _vehicle engineOn true;
        _vehicles pushBack _vehicle;
        sleep 1;
	};
} forEach _list;

    {_group addVehicle _x} forEach _vehicles;
    _group allowFleeing 0;

[_units, _vehicles, _group]