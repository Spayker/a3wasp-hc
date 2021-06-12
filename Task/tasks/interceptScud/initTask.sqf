/*
==MISSION: SAVE IMPORTANT TOURIST AND GET IMOPRTANT DATA==
*/

params [["_side", civilian], ["_taskName", "unnamed"]];
private ["_closestTowns", "_selectedTowns", "_twn", "_mhqs", "_mhq"];

_closestTowns = [];
_selectedTowns = [];
_twn = objNull;

{
    if(_x getVariable "wf_active" == false && count (_x getVariable ["camps", []]) > 0) then {
        _townSpeciality = _x getVariable ["townSpeciality", []];
        if(count _townSpeciality == 0) then { _selectedTowns pushBack _x }
	}
} forEach towns;

//--Select random from 6 nearest towns--
_mhqs = _side call WFCO_FNC_GetSideHQ;

while {count _closestTowns < count _selectedTowns} do {
    {
        _closest = true;
        _twn = _x;
        {
            _mhq = [_twn,_mhqs] call WFCO_FNC_GetClosestEntity;
            if((_twn distance _mhq) > (_x distance _mhq)) exitWith {
                _closest = false;
            };
        } forEach (_selectedTowns - [_twn]);

        if(_closest) then {
            _closestTowns pushBack _twn;
            _selectedTowns deleteAt _forEachIndex;
        };
    } forEach _selectedTowns;
};

for "_i" from 5 to 0 step -1 do {
    if(count _closestTowns >= (_i + 1)) exitWith {
        _selectRnd = [];
        for "_j" from 0 to _i do { _selectRnd pushBack (_closestTowns # _j) };
        _twn = selectRandom _selectRnd
    }
};

if(!isNull _twn) then {
	_twnPos = getPos _twn;
	_twnPos set [0, (_twnPos # 0) + random [-75, 0, 75]];
	_twnPos set [1, (_twnPos # 1) + random [-75, 0, 75]];

	[_side, "NewMissionAvailable"] remoteExecCall ["WFSE_FNC_SideMessage", 2];
	[15, _side, _twn getVariable ["name", "Town"], _twnPos] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
	["TASK DIRECTOR", format["interceptScud\initTask.sqf: tasks assigned for %1 in town %2", _side, _twn getVariable ["name", "Town"]]] call WFCO_FNC_LogContent;
	sleep 5;		
	["CommonText", "STR_WF_M_InterceptScudDesc", _twn getVariable ["name", "Town"]] remoteExec ["WFCL_FNC_LocalizeMessage", _side];

	_vehicle = [WF_MOBILE_TACTICAL_MISSILE_LAUNCHER_TYPE, [_twnPos, 75, 360, 5, 0] call BIS_fnc_findSafePos, WF_C_CIV_ID, 0, false, nil, nil, nil, ""] Call WFCO_FNC_CreateVehicle;
    _units = [_vehicle];

	while { alive _vehicle && isNull (driver _vehicle) } do { sleep 5 };
    _driver = driver _vehicle;
    _driverSide = side _driver;

    [16, _driverSide] remoteExecCall ["WFCL_FNC_svTrstTsk", _driverSide, true];
    switch (_driverSide) do {
        case west: {
            [17, east] remoteExecCall ["WFCL_FNC_svTrstTsk", east, true];
            [17, resistance] remoteExecCall ["WFCL_FNC_svTrstTsk", resistance, true]
        };
        case east: {
            [17, west] remoteExecCall ["WFCL_FNC_svTrstTsk", west, true];
            [17, resistance] remoteExecCall ["WFCL_FNC_svTrstTsk", resistance, true]
        };
        case resistance: {
            [17, west] remoteExecCall ["WFCL_FNC_svTrstTsk", west, true];
            [17, east] remoteExecCall ["WFCL_FNC_svTrstTsk", east, true]
        }
    };

    ["TASK DIRECTOR", format["interceptScud\initTask.sqf:  %1 side intercept SCUD task complete", _driverSide]] call WFCO_FNC_LogContent;
    sleep 15
};

["TASK DIRECTOR", "interceptScud\initTask.sqf: interceptScud task COMPLETE!"] call WFCO_FNC_LogContent