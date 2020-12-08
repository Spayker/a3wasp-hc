params["_town", "_camps", "_side", "_vehGroups", "_infGroups"];
private ["_spawn_inf_radius","_position","_camp","_index","_roadList","_road","_roadConnectedTo",
"_selectedRoad", "_secondWaveSpawnRange"];

_town setVariable ['wf_spawning', true]; //--Mark town as spawning--
_spawn_inf_radius = 25;
_secondWaveSpawnRange = (_town getVariable "range") / 2;

_spawnGroups = {
    private ["_groupsToBeSpawned", "_position", "_town", "_roadList", "_road", "_roadConnectedTo", "_connectedRoad"];
    params ["_isInfantry", "_isFirstWave", "_side", "_groupsToBeSpawned", "_town", ["_spawnRadius", 25]];

    _townPos = getPosATL _town;
    for '_i' from 0 to (count(_groupsToBeSpawned)-1) do {
        _position = [];
        if (_isFirstWave)then {
            _position = [_townPos, _spawnRadius, true] call WFCO_fnc_getEmptyPosition
        } else {
            _minimalRadius = _spawnRadius - 100;
            _position = [_townPos, _minimalRadius, true] call WFCO_fnc_getEmptyPosition;
            _spawnRadius = _minimalRadius
        };

        _groupToBeSpawned = _groupsToBeSpawned # _i;
        if(count _groupsToBeSpawned > _i) then {
            if (isNil '_position') then {
                ["WARNING", Format["fn_SpawnTownGroups.sqf: position is nil for _town %1, _side %2, groups %3 ", _town,_side,_groupToBeSpawned]] Call WFCO_FNC_LogContent
            } else {
                [_town, _side, [_groupToBeSpawned], [_position]] spawn WFHC_FNC_CreateTownUnits
            }
        };

        if (_isFirstWave) then {
        if(_isInfantry) then {
            _spawnRadius = _spawnRadius + 25;
                sleep (count (_groupToBeSpawned) * 2)
        } else {
                sleep (count (_groupToBeSpawned) * 4)
        }
    }
    }
};

if (count _camps > 0) then {
	for '_i' from 0 to (count(_camps)-1) do {
		_position = [];
        _camp = _camps select floor (random count _camps);
        _index = _camps find _camp;
        if(_index > -1)then{_camps deleteAt _index};
        _position = ([getPosATL _camp, _spawn_inf_radius] call WFCO_FNC_GetSafePlace);

        if(count _infGroups > _i) then {
            [_town, _side, [_infGroups # _i], [_position], _camp] spawn WFHC_FNC_CreateTownUnits
        };
        _infGroups deleteAt _i;
        sleep (random 5);
    };
};

_allGroups = _infGroups + _vehGroups;
_allGroupCount = count(_allGroups);

_grpCountThresshold = 6;
_campsCount = count _camps;
if (_campsCount > 0) then {
    _grpCountThresshold = _grpCountThresshold + _campsCount
};

_defenceStaticGroup = 0;
if(_side == resistance) then { _defenceStaticGroup = 1 };

if((_allGroupCount + _campsCount + _defenceStaticGroup) > _grpCountThresshold) then {

    _waveInfGroups = [];
    _waveVehGroups = [];

    if (count(_infGroups) > 0) then {
        for "_i" from 0 to ((count(_infGroups)/2)) - _defenceStaticGroup do {
            _waveInfGroups pushBack (_infGroups # _i);
            _infGroups deleteAt _i
        }
    };

    if (count(_vehGroups) > 0) then {
        for "_i" from 0 to ((count(_vehGroups)/2)) - _defenceStaticGroup do {
            _waveVehGroups pushBack (_vehGroups # _i);
            _vehGroups deleteAt _i
        }
    };

    if (count _waveInfGroups > 0) then { [true, true, _side, _waveInfGroups, _town] call _spawnGroups };
    if (count _waveVehGroups > 0) then { [false, true, _side, _waveVehGroups, _town] call _spawnGroups };
    _town setVariable ['wf_spawning', false];

    _allUnits = 0;
    _townSpawnedGroups = _town getVariable 'wf_town_teams';
    for "_i" from 0 to (count (_townSpawnedGroups) - 1) do {
        {
            if (alive _x) then { _allUnits = _allUnits + 1 }
        } forEach units (_townSpawnedGroups # _i)
    };

    _town setVariable ['wf_rest_infantry_groups', _infGroups];
    _town setVariable ['wf_rest_vehicle_groups', _vehGroups];
    while {_town getVariable "wf_active" && _allUnits > 10} do {
        _allUnits = 0;
        for "_i" from 0 to (count (_townSpawnedGroups) - 1) do {
            {
                if (alive _x) then { _allUnits = _allUnits + 1 }
            } forEach units (_townSpawnedGroups # _i)
        };
        sleep 3
    };
    if (_town getVariable "wf_active") then {
        _town setVariable ['wf_spawning', true];
        [true, false, _side, _infGroups, _town, _secondWaveSpawnRange] call _spawnGroups;
        [false, false, _side, _vehGroups, _town, _secondWaveSpawnRange] call _spawnGroups;
        _town setVariable ['wf_rest_infantry_groups', []];
        _town setVariable ['wf_rest_vehicle_groups', []];
    }
} else {
    _town setVariable ['wf_spawning', true];
    [true, true, _side, _infGroups, _town] call _spawnGroups;
    [false, true, _side, _vehGroups, _town] call _spawnGroups
};

_town setVariable ['wf_spawning', false] //--Mark town as finished spawning--


