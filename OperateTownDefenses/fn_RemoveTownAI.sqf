params[["_town", objNull],["_deleteOnlyMen", 0],["_isPersistGroup", true]];
private ["_groupsFromServer", "_town_teams", "_town_vehicles"];

["INFORMATION", format ["fn_RemoveTownAI.sqf: Begin remove town AI for [%1]. Delete only men? - [%2]", _town, _deleteOnlyMen]] call WFCO_FNC_LogContent;
_groupsFromServer = ["WFSE_FNC_GetTownActiveGroups", player, [_town], 3000] call WFCL_FNC_remoteExecServer;
_town_teams = _groupsFromServer # 0;
_town_vehicles = _groupsFromServer # 1;
_town_teams = _town_teams - [grpNull];
_town_vehicles = _town_vehicles - [grpNull];

_sideID = _town getVariable ["sideID", 2];
_townSide = (_sideID) call WFCO_FNC_GetSideFromID;

["INFORMATION", format ["fn_RemoveTownAI.sqf: Groups recieved from server for [%1]: %2", _town, _town_teams]] call WFCO_FNC_LogContent;
["INFORMATION", format ["fn_RemoveTownAI.sqf: Vehicles recieved from server for [%1]: %2", _town, _town_vehicles]] call WFCO_FNC_LogContent;

if(isNil "_groupsFromServer") then {
    ["INFORMATION", "_groupsFromServer is nil, setting to [[], []]"] call WFCO_FNC_LogContent;
	_groupsFromServer = [[], []];
};

if(isNil "_town_teams") then { _town_teams = [] };
if(isNil "_town_vehicles") then { _town_vehicles = [] };

_groupsToSave = [];
_groupsVehToSave = [];
if(_deleteOnlyMen > 0) then {
	if(_deleteOnlyMen == 1) then {
		{
            if!(isNull _x) then {
                {
                    if(vehicle _x == _x) then {
                        _x setDamage 1;
                    };
                } forEach units _x;
                deleteGroup _x;
            };
        } forEach (_town_teams);
	} else {//--Remove only man which is in building--
		{
            if(!isNull _x) then {
                {
                    if(!isNull _x) then {
                        if(vehicle _x == _x && alive _x) then {
                            if([_x] call WFCO_FNC_IsUnitInBuilding) then {
                                _x setDamage 1;
                            };
                        };
                    };
                } forEach units _x
            }
        } forEach (_town_teams)
    }
} else {
	//--- Teams Units.
	{
        if(_isPersistGroup && !isNull _x) then {
            _groupToSave = [];

        	{
        		if(alive _x && (vehicle _x == _x) && (_townSide == side _x)) then { _groupToSave pushBack (typeOf _x) }
        	} forEach (units _x);

            if (count _groupToSave > 0) then { _groupsToSave pushBack _groupToSave }
        };

		{
		    _vehicle = vehicle _x;
			if(_vehicle != _x) then {
                _vehicle deleteVehicleCrew _x
			} else {
                deleteVehicle _x
			};

            if!(isNil "_vehicle") then { deleteVehicle _vehicle }
        } forEach units _x;

        deleteGroup _x
	} forEach _town_teams;

    [_town] remoteExecCall ["WFSE_FNC_MarkTownInactive", 2];
};

if(_isPersistGroup) then {
    _vehCounter = 0;
    _groupToSave = [];
	{
        if(alive _x) then {
            _vehicleType = typeOf _x;
            _vehicleSideId = getNumber(configFile >> "CfgVehicles" >> _vehicleType >> "side");
            if (_sideID == _vehicleSideId) then {
        if (_vehCounter == 2) then {
            _groupsVehToSave pushBack _groupToSave;
            _vehCounter = 0;
                _groupToSave = []
            };

                _groupToSave pushBack (_vehicleType);
            _vehCounter = _vehCounter + 1
            }
        }
    } forEach (_town_vehicles);

    _restInfantryGroups = _town getVariable ['wf_rest_infantry_groups', []];
    ["INFORMATION", format ["fn_RemoveTownAI.sqf: rest infantry squads to be spawned for [%1]: %2", _town, _restInfantryGroups]] call WFCO_FNC_LogContent;

    _restVehicleGroups = _town getVariable ['wf_rest_vehicle_groups', []];
    ["INFORMATION", format ["fn_RemoveTownAI.sqf: rest vehicles to be spawned for [%1]: %2", _town, _restVehicleGroups]] call WFCO_FNC_LogContent;

    if (count _groupToSave > 0) then { _groupsVehToSave pushBack _groupToSave };

    if (count _restInfantryGroups > 0) then {
        { _groupsToSave pushBack _x } forEach _restInfantryGroups
    };

    if (count _restVehicleGroups > 0) then {
        { _groupsVehToSave pushBack _x } forEach _restVehicleGroups
    };

    _town setVariable ['wf_rest_vehicle_groups', [], true];
    _town setVariable ['wf_rest_infantry_groups', [], true];
    ["INFORMATION", format ["fn_RemoveTownAI.sqf: filtered infantry groups to be saved in [%1]: %2", _town, _groupsToSave]] call WFCO_FNC_LogContent;
    ["INFORMATION", format ["fn_RemoveTownAI.sqf: filtered vehicles to be saved in [%1]: %2", _town, _groupsVehToSave]] call WFCO_FNC_LogContent;
    [_town, _groupsToSave, _groupsVehToSave] remoteExecCall ["WFSE_FNC_SaveTownSurvivedGroups", 2]
};

