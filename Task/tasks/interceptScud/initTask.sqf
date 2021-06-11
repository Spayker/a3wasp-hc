/*
==MISSION: SAVE IMPORTANT TOURIST AND GET IMOPRTANT DATA==
*/

params [["_side", civilian], ["_taskName", "unnamed"]];
private ["_closestTowns", "_guertowns", "_twn", "_mhqs", "_mhq"];

_closestTowns = [];
_guertowns = [];
_twn = objNull;

{
    if(_x getVariable "sideID" == 2 && _x getVariable "wf_active" == false && count (_x getVariable ["camps", []]) > 0) then {
        _townSpeciality = _x getVariable ["townSpeciality", []];
        if(count _townSpeciality <= 0) then { _guertowns pushBack _x }
	};
} forEach towns;

//--Select random from 6 nearest towns--
_mhqs = _side call WFCO_FNC_GetSideHQ;

while {count _closestTowns < count _guertowns} do {
    {
        _closest = true;
        _twn = _x;
        {
            _mhq = [_twn,_mhqs] call WFCO_FNC_GetClosestEntity;
            if((_twn distance _mhq) > (_x distance _mhq)) exitWith {
                _closest = false;
            };
        } forEach (_guertowns - [_twn]);

        if(_closest) then {
            _closestTowns pushBack _twn;
            _guertowns deleteAt _forEachIndex;
        };
    } forEach _guertowns;
};

for "_i" from 5 to 0 step -1 do {
    if(count _closestTowns >= (_i + 1)) exitWith {
        _selectRnd = [];
        for "_j" from 0 to _i do {
            _selectRnd pushBack (_closestTowns # _j);
        };
        _twn = selectRandom _selectRnd;
    };
};

if(!isNull _twn) then {
	_twnPos = getPos _twn;
	_twnPos set [0, (_twnPos # 0) + random [-75, 0, 75]];
	_twnPos set [1, (_twnPos # 1) + random [-75, 0, 75]];
	[_side,"NewMissionAvailable"] remoteExecCall ["WFSE_FNC_SideMessage", 2];
	[0, _side, _twn getVariable ["name", "Town"], _twnPos] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
	["TASK DIRECTOR", format["interceptScud\initTask.sqf: tasks assigned for %1 in town %2", _side, _twn getVariable ["name", "Town"]]] call WFCO_FNC_LogContent;
	sleep 5;		
	["CommonText", "STR_WF_M_InterceptScudDesc", _twn getVariable ["name", "Town"]] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
	
	while { _twn getVariable "sideID" == 2 } do { sleep 5 };
	
	_twnSideID = _twn getVariable ["sideID", WF_C_CIV_ID];
	_twnSide = _twnSideID call WFCO_FNC_GetSideFromID;
	_sideID = (_side) call WFCO_FNC_GetSideID;
	
	if(_twnSideID == _sideID) then {
		[1, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
		
		["TASK DIRECTOR", format["interceptScud\initTask.sqf: DeliverTouristTown %1 by side %2 succeeded complete", _twn getVariable ["name", "Town"], _side]] call WFCO_FNC_LogContent;
		sleep 25;

		_vehicle = [WF_MOBILE_TACTICAL_MISSILE_LAUNCHER_TYPE, [_twnPos, 75, 360, 5, 0] call BIS_fnc_findSafePos, _sideID, 0, false, nil, nil, nil, ""] Call WFCO_FNC_CreateVehicle;
		_units = [_vehicle];
		
		[2, _side, nil, _twnPos] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
		["TASK DIRECTOR", format["interceptScud\initTask.sqf: assigned task %1 for side %2", localize "STR_WF_M_DeliverTouristTalk", _side]] call WFCO_FNC_LogContent;

		//--spawn a thread which checking task activation--
		[_units, _side, _taskName] spawn {
			params["_units", "_side", "_taskName"];
			_allAlive = [];
			{ if(alive _x) then { _allAlive pushBack (name _x) } } forEach _units;
			
			while { count _allAlive > 0 } do {				
				_totTalkComplete = 0;
				{
					if((name _x) in _allAlive) then {
						if(!alive _x) then { _allAlive = _allAlive - [name _x] };

						if(count _allAlive > 0) then {
							if(_x getVariable "_talkComplete" == 1) then { _totTalkComplete = _totTalkComplete + 1; };
							if(_totTalkComplete > 0) exitWith {
								_allAlive = 0;								
								[3, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
								["TASK DIRECTOR", format["interceptScud\initTask.sqf: task %1 for side %2 SUCCEEDED", "InterceptScud", _side]] call WFCO_FNC_LogContent;
								
								sleep 5;
								
								[4, _side, nil, nil, getPosATL _building] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
								["CommonText", "STR_WF_M_ScudIsIntercepted"] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
								
								breakTo "exitInterceptScud";
							};
						} else {						
							_allAlive = 0;
							[8, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
							[9, _side, nil, nil, nil, name _x] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
							["CommonText", "STR_WF_M_DeliverTouristOneOrMoreDown", name _x] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
							["TASK DIRECTOR", format["interceptScud\initTask.sqf: task %1 for side %2 FAILED: %3", "InterceptScud", _side, localize "STR_WF_M_DeliverTouristOneOrMoreDown"]] call WFCO_FNC_LogContent;

							[_units] spawn {
								params ["_units"];
								{
									_building = nearestBuilding _x;
									_wp = (group _x) addWaypoint[ getPos _building ,0];
									_wp waypointAttachObject _building;
								} forEach _units;
								
								sleep 60;
								{
									deleteVehicle _x;
									deleteGroup (group _x);
								} forEach _units;
							};
							
							breakTo "exitInterceptScud";
						};
					};
				} forEach _units;
			
				sleep 3;
			};

			scopeName "exitInterceptScud";
			missionNameSpace setVariable [format["taskIsRun%1", _taskName], false];
		};
		sleep 5
	} else {		
		if(_twnSideID != _sideID) then {
			[10, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];			
			[11, _side, _twn getVariable ["name", "Town"]] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
			["CommonText", "STR_WF_M_DeliverTouristTownLost", _twn getVariable ["name", "Town"]] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
			sleep 20;
			["CommonText", "STR_WF_M_DeliverTouristBountyLost", _twn getVariable ["name", "Town"]] remoteExec ["WFCL_FNC_LocalizeMessage", _twnSide];
			[12, _twnSide, _twn getVariable ["name", "Town"], getPos _twn] remoteExecCall ["WFCL_FNC_svTrstTsk", _twnSide, true];
			[_twnSide, 750] call WFCO_FNC_ChangeSideSupply;
			["CommonText", "STR_WF_M_DeliverTouristBountyLostMessage", 750] remoteExec ["WFCL_FNC_LocalizeMessage", _twnSide];
			sleep 15;
			[13, _twnSide] remoteExecCall ["WFCL_FNC_svTrstTsk", _twnSide, true];
			missionNameSpace setVariable [format["taskIsRun%1", _taskName], false];
		};
	};
};

["TASK DIRECTOR", "interceptScud\initTask.sqf: interceptScud task COMPLETE!"] call WFCO_FNC_LogContent;