/*
==MISSION: SAVE IMPORTANT TOURIST AND GET IMOPRTANT DATA==
*/

params [["_side", CIVILIAN], ["_taskName", "unnamed"]];
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
	["TASK DIRECTOR", format["saveTourists\initTask.sqf: tasks assigned for %1 in town %2", _side, _twn getVariable ["name", "Town"]]] call WFCO_FNC_LogContent;
	sleep 5;		
	["CommonText", "STR_WF_M_DeliverTouristTownDesc", _twn getVariable ["name", "Town"]] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
	
	while { _twn getVariable "sideID" == 2 } do {
		sleep 5;
	};
	
	_twnSideID = _twn getVariable ["sideID", WF_C_CIV_ID];
	_twnSide = _twnSideID call WFCO_FNC_GetSideFromID;
	_sideID = (_side) call WFCO_FNC_GetSideID;
	
	if(_twnSideID == _sideID) then {
		[1, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
		
		["TASK DIRECTOR", format["saveTourists\initTask.sqf: DeliverTouristTown %1 by side %2 succeeded complete", _twn getVariable ["name", "Town"], _side]] call WFCO_FNC_LogContent;
		sleep 25;
		civilian setFriend [_side, 1];
		_group1 = createGroup civilian;
		_group2 = createGroup civilian;
		_group3 = createGroup civilian;
		_units = [];

        _hostages = call compile preprocessFileLineNumbers "Common\Warfare\Config\Config_SaveTouristUnits.sqf";

		_units pushBack (_group1 createUnit [_hostages # (random ((count _hostages) - 1)), [_twnPos, 75, 360, 5, 0] call BIS_fnc_findSafePos, [], 1, "FORM"]);
		_units pushBack (_group2 createUnit [_hostages # (random ((count _hostages) - 1)), [_twnPos, 75, 360, 5, 0] call BIS_fnc_findSafePos, [], 1, "FORM"]);
		_units pushBack (_group3 createUnit [_hostages # (random ((count _hostages) - 1)), [_twnPos, 75, 360, 5, 0] call BIS_fnc_findSafePos, [], 1, "FORM"]);	
		
		[2, _side, nil, _twnPos] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
		["TASK DIRECTOR", format["saveTourists\initTask.sqf: assigned task %1 for side %2", localize "STR_WF_M_DeliverTouristTalk", _side]] call WFCO_FNC_LogContent;

		//--Set mission done flag on each unit--
		{
			_x allowFleeing 0;
		
			if(alive _x) then {
				_x setVariable ["_talkComplete", 0];
			};

			_x setSkill ["endurance", 1];
			_x setSkill ["spotDistance", 0];
			_x setSkill ["spotTime", 0];
			_x setSkill ["courage", 1];
		} forEach _units;

		//--spawn a thread which checking task activation--
		[_units, _side, _taskName] spawn {
			params["_units", "_side", "_taskName"];
			_allAlive = [];
			{ if(alive _x) then {_allAlive pushBack (name _x);}; } forEach _units;
			
			while { count _allAlive > 0 } do {				
				_totTalkComplete = 0;
				{
					if((name _x) in _allAlive) then {
						if(!alive _x) then { _allAlive = _allAlive - [name _x]; };					
						if(count _allAlive > 0) then {
							if(_x getVariable "_talkComplete" == 1) then { _totTalkComplete = _totTalkComplete + 1; };
							if(_totTalkComplete > 0) exitWith {
								_allAlive = 0;								
								[3, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
								["TASK DIRECTOR", format["saveTourists\initTask.sqf: task %1 for side %2 SUCCEEDED", "SaveTourists", _side]] call WFCO_FNC_LogContent;
								_bldFinded = false;
								_building = nearestBuilding ((getPos _x) getPos [250 * sqrt random 1, random 360]);
								
								while { !_bldFinded } do {
									_bndBox = boundingBoxReal _building;
									if(((_bndBox # 1) # 0) < 3) then { 
										_building = nearestBuilding ((getPos _x) getPos [250 * sqrt random 1, random 360]);
									} else {
										_bldFinded = true;
									};
								};
								
								_building setDammage 0;
								
								sleep 5;
								
								[4, _side, nil, nil, getPosATL _building] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
								["CommonText", "STR_WF_M_DeliverTouristGiveSupport"] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
								
								[_x, "gotohole", 100] call CBA_fnc_globalSay3d;
								
								_wp = (group (_units # 0)) addWaypoint[ getPos _building ,0];
								_wp waypointAttachObject _building;
								for [{_ii = 1}, {_ii < count _units}, {_ii = _ii + 1}] do { 
									_wpPos = getPos _building;
									if(_ii == 1) then {	_wpPos set [0, (_wpPos # 0) + 3]; } else { _wpPos set [1, (_wpPos # 1) + 3]; };
									_wp = (group (_units # _ii)) addWaypoint[ _wpPos ,0]; 
								};	
								
								[_building, _units, _x getVariable "_playerName", _side, _taskName] spawn {
									params ["_bld", "_units", "_playerName", "_side", "_taskName"];
									
									_boundingBox = boundingBox _bld;
									_min = _boundingBox # 0;
									_max = _boundingBox # 1;
									_inside = false;
									_untIndx = 0;
									
									_allAlive = [];
									{ if(alive _x) then {_allAlive pushBack (name _x);}; } forEach _units;
									
									while { !_inside } do {
										{
											if(!alive _x) then { _allAlive = _allAlive - [name _x]; };
										
											if(count _allAlive < 1) exitWith {
												_inside = true;
												[5, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
												[6, _side, nil, nil, nil, name _x] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
												["CommonText", "STR_WF_M_DeliverTouristOneOrMoreDown", name _x] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
												
												[_units] spawn {
													params ["_units"];
													{
														_bld = nearestBuilding _x;
														_wp = (group _x) addWaypoint[ getPos _bld ,0];
														_wp waypointAttachObject _bld;
													} forEach _units;
													
													sleep 60;
													{
														deleteVehicle _x;
														deleteGroup (group _x);
													} forEach _units;
												};
												
												missionNameSpace setVariable [format["taskIsRun%1", _taskName], false];
											};
											_relPos = _bld worldToModel (getPosATL _x);
											
											_myX = _relPos # 0;
											_myY = _relPos # 1;
											_myZ = _relPos # 2;
											
											if ((_myX > ((_min # 0) - 7.5)) and (_myX < ((_max # 0) + 7.5))) then {
												if ((_myY > ((_min # 1) - 7.5)) and (_myY < ((_max # 1) + 7.5))) then {
													if ((_myZ > ((_min # 2) - 7.5)) and (_myZ < ((_max # 2) + 7.5))) then {															
														_inside = true;
														sleep 1.5;
														[_x, "M3_speech", 100] call CBA_fnc_globalSay3d;
														
														if((_units # 0) == _x ) then { _untIndx = 1; };
														sleep 22.5;
														[(_units # (_untIndx)), "RUFF_speech", 100] call CBA_fnc_globalSay3d;
													};
												};
											};
											
											if(_inside) exitWith {};
										} forEach _units;
										
										sleep 3;
									};
									
									sleep 60;
									{ deleteVehicle _x; deleteGroup (group _x);} forEach _units;							
									
									_logik = objNull;

									if(_side == west) then {
										_logik = (east) call WFCO_FNC_GetSideLogic;
									};

									if(_side == east) then {
										_logik = (west) call WFCO_FNC_GetSideLogic;
									};
									
									_enemyStartPos = getPos (_logik getVariable "wf_startpos");
									
									[7, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
									sleep 0.5;
									["CommonText", "STR_WF_M_DeliverTouristBounty", _playerName] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
									sleep 10;
									["CommonText", "STR_WF_M_DeliverTouristBountySupply", 2500] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
									[_side, 2500] call WFCO_FNC_ChangeSideSupply;
									sleep 3;
									["CommonText", "STR_WF_M_DeliverTouristBountyMoney", _playerName, 20000] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
									
									{
									    if(name _x == _playerName) exitWith {
									        [_x, score _x + 20] remoteExecCall ["WFSE_FNC_RequestChangeScore", 2];
											20000 remoteExecCall ["WFCL_FNC_ChangePlayerFunds", _x];
									    };
									} forEach (allPlayers - entities "HeadlessClient_F");

									[14, _side, nil, nil, nil, nil, _enemyStartPos] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
									
									//--Destroy building with tourists--
									_bld setDamage 1;
									missionNameSpace setVariable [format["taskIsRun%1", _taskName], false];																		
								};
								
								breakTo "exitSaveTourists";
							};
						} else {						
							_allAlive = 0;
							[8, _side] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
							[9, _side, nil, nil, nil, name _x] remoteExecCall ["WFCL_FNC_svTrstTsk", _side, true];
							["CommonText", "STR_WF_M_DeliverTouristOneOrMoreDown", name _x] remoteExec ["WFCL_FNC_LocalizeMessage", _side];
							["TASK DIRECTOR", format["saveTourists\initTask.sqf: task %1 for side %2 FAILED: %3", "SaveTourists", _side, localize "STR_WF_M_DeliverTouristOneOrMoreDown"]] call WFCO_FNC_LogContent;

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
							
							breakTo "exitSaveTourists";
						};
					};
				} forEach _units;
			
				sleep 3;
			};

			scopeName "exitSaveTourists";
			missionNameSpace setVariable [format["taskIsRun%1", _taskName], false];
		};

		sleep 5;		

		{
			_unit = _x;
			if(alive _unit) then {
				_wp =_group1 addWaypoint [_twnPos, 0];
				_wp =_group2 addWaypoint [_twnPos, 0];
				_wp =_group3 addWaypoint [_twnPos, 0];
				[_unit, _side] spawn {
					params ["_unt", "_side"];
					while { alive _unt } do {
						_ents = _unt nearEntities ["Man", 5];						
						{								
							if(side _x == _side && (isPlayer (leader (group _x)))) exitWith { 
								_unt setVariable ["_talkComplete", 1];
								_unt setVariable ["_playerName", name (leader (group _x))];
							};
						} forEach _ents;
						
						sleep 3;				
					};
				};
			};
		} forEach _units;
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

["TASK DIRECTOR", "saveTourists\initTask.sqf: SaveTourists taks COMPLETE!"] call WFCO_FNC_LogContent;