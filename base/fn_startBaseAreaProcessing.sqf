private["_brr","_mbr","_onAreaRemoved","_side","_logik","_buildings","_command","_service","_aar","_areas","_grp",
"_areas_old","_playersAreas","_area","_playerAreas","_fortifications"];

_brr = missionNamespace getVariable "WF_C_BASE_AREA_RANGE";
_mbr = missionNamespace getVariable "WF_C_BASE_HQ_BUILD_RANGE";
_baseareaRange = _brr + _mbr;

_onAreaRemoved = {
	private ["_delete", "_objects"];
	params ["_center", "_side", "_areas", "_baseareaRange"];

	_objectsToFind = (missionNamespace getVariable Format["WF_%1DEFENSENAMES", _side]);
	_objects = nearestObjects [_center, _objectsToFind, (missionNamespace getVariable "WF_C_BASE_AREA_RANGE") + (missionNamespace getVariable "WF_C_BASE_HQ_BUILD_RANGE")];

	if(isNil "_baseareaRange") then { _baseareaRange = (missionNamespace getVariable "WF_C_BASE_AREA_RANGE") + (missionNamespace getVariable "WF_C_BASE_HQ_BUILD_RANGE"); };

	{
	    _objects = _objects - (nearestObjects [getPosATL _x, missionNamespace getVariable Format["WF_%1DEFENSENAMES", _side], _baseareaRange])
	} forEach _areas;

	{
		if !(isNil {_x getVariable "wf_defense"}) then {
			_delete = true;
			if (_x isKindOf "StaticWeapon") then {
				_unit = gunner _x;
				if (alive _unit) then {
					if (isNil {(group _unit) getVariable "wf_funds"}) then {
						deleteVehicle _unit;
					} else {
						_delete = false;
					};
				};
			};
			if (_delete) then {deleteVehicle _x};
		};
	} forEach _objects;
};

sleep 30;

while {!WF_GameOver} do {
	{
		_side = _x;
		_logik = (_side) Call WFCO_FNC_GetSideLogic;

		_hqs = (_side Call WFCO_FNC_GetSideHQ);
		{
		    if !(_x isKindOf 'Warfare_HQ_base_unfolded') then { _hqs = _hqs - [_x] }
		} forEach _hqs;

		_buildings = (_side Call WFCO_FNC_GetSideStructures) + _hqs;
		_command=[_side,missionNamespace getVariable Format["WF_%1COMMANDCENTERTYPE",str _side],_buildings] Call WFCO_FNC_GetFactories;
		_service=[_side,missionNamespace getVariable Format["WF_%1SERVICEPOINTTYPE",str _side],_buildings] Call WFCO_FNC_GetFactories;
		_aar = [_side,missionNamespace getVariable Format["WF_%1AARADARTYPE",str _side],_buildings] Call WFCO_FNC_GetFactories;
		_arr = [_side,missionNamespace getVariable Format["WF_%1ArtyRadarTYPE",str _side],_buildings] Call WFCO_FNC_GetFactories;
		_buildings = _buildings - _command - _service - _aar - _arr;
		_areas = _logik getVariable "wf_basearea";

		{
			_structure = [_x, _buildings] Call WFCO_FNC_GetClosestEntity;
			if (!isNull _structure) then {
				if (_structure distance _x > (_brr + _mbr)) then {
					//--- On deletion, remove the statics/defenses later.
					[getPosATL _x, _side, _areas, _baseareaRange] Spawn _onAreaRemoved;
					_areas deleteAt (_forEachIndex);
					_areas = _areas - [objNull];
					_grp = group _x;
					deleteVehicle _x;
					deleteGroup _grp;
					_logik setVariable ["wf_basearea", _areas, true];
				}
			} else {
			    [getPosATL _x, _side, _areas, _baseareaRange] Spawn _onAreaRemoved;
                _areas deleteAt (_forEachIndex);
                _areas = _areas - [objNull];
                _grp = group _x;
                deleteVehicle _x;
                deleteGroup _grp;
                _logik setVariable ["wf_basearea", _areas, true]
			}
		} forEach _areas;
	} forEach WF_PRESENTSIDES;

    _playersAreas = []; //--All forts areas--
    //--Refresh players fortifications areas--
    {
        _playersAreas = _playersAreas + (_x # 1);
    } forEach (missionNamespace getVariable ["WF_PLAYERS_FORTIFICATIONS_AREA", []]);

    {
        _area = _x;
        //--allUnits is faster in 1.01 times then nearEntities (about 1 - 2 % difference in current situation)--
        //--Difference growing when you have more any objects in the area--
        if({alive _x && _x inArea [_area, _baseareaRange, _baseareaRange, 0, false]} count allUnits > 0) then {
            //--Update presence in zone--
            _area setVariable ["refresh_time", time];
        };

        _fortifications = _area getVariable ["fortifications", []];
        _fortifications = _fortifications - [objNull];
        //--Delete overdue and empty area--
        if((time - (_area getVariable ["refresh_time", time])) > WF_C_UNITS_EMPTY_TIMEOUT ||
            count _fortifications <= 0) then {
            {
                deleteVehicle _x;
            } forEach (_area getVariable ["fortifications", []]);

            deleteGroup (group _area);
            deleteVehicle _area;
        };
    } forEach _playersAreas;

    _playersAreas = missionNamespace getVariable ["WF_PLAYERS_FORTIFICATIONS_AREA", []];
    {
        _playerAreas = _x # 1;
        _playerAreas = _playerAreas - [objNull];

        //--Refresh areas data on client--
        missionNamespace setVariable ["WF_FORTITIFACTIONS_AREAS", _playerAreas, _x # 0];
        _playersAreas set [_forEachIndex, [_x # 0, _playerAreas]];
    } forEach _playersAreas;

    missionNamespace setVariable ["WF_PLAYERS_FORTIFICATIONS_AREA", _playersAreas];

	sleep 15;
};