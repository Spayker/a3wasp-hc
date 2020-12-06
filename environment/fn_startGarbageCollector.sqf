private["_WF_C_UNITS_CLEAN_TIMEOUT"];

_WF_C_UNITS_CLEAN_TIMEOUT = missionNamespace getVariable ["WF_C_UNITS_CLEAN_TIMEOUT", 120];
_miscObjectTypes = ["WeaponHolder", "GroundWeaponHolder", "WeaponHolderSimulated", "CraterLong_small", "CraterLong"];

while {!WF_GameOver} do {
	_alldead = allDead - [objNull];

	{
	    _object = _x;
		_wf_trashed_time = _object getVariable ["wf_trashed_time", 0];

	    if(_wf_trashed_time == 0) then {
	        _wf_trashed_time = time + (selectRandom [5, 10, 15]);
            _object setVariable ["wf_trashed_time", _wf_trashed_time]
        };

		if((time - _wf_trashed_time - 5) > _WF_C_UNITS_CLEAN_TIMEOUT) then {
            if !(isNull _object) then {
            	_isMan = (_object isKindOf "Man");
            	_group = [grpNull, group _object] select (_isMan);
            	_delay = missionNamespace getVariable ["WF_C_UNITS_CLEAN_TIMEOUT", 120];

                if !(isNull _object) then {
                    ["INFORMATION", Format["fn_TrashObject.sqf: Deleting [%1], it has been [%2] seconds.", _object, _delay]] Call WFCO_FNC_LogContent;

                    if (_isMan) then {
                        if (!isNull (objectParent _object)) then {
                            (objectParent _object) deleteVehicleCrew _object
                        } else {
                            deleteVehicle _object
                        };

                        if !(isNull _group) then {
                            if (isNil {_group getVariable "wf_persistent"}) then {if (count (units _group) <= 0) then {deleteGroup _group}}
                        }
                    } else {
                        _crew = crew _object;
                        if (count _crew > 0) then {
                            {
                                ["INFORMATION", Format["fn_TrashObject.sqf: Deleting crew unit [%1] of trashed object [%2].", _x, _object]] Call WFCO_FNC_LogContent;
                                _object deleteVehicleCrew _x
                            } forEach _crew;
                        };

                        deleteVehicle _object
                    }
                }
            };

            ["INFORMATION", Format["fn_startGarbageCollector.sqf: Exec WFCO_FNC_TrashObject for [%1].", _x]] Call WFCO_FNC_LogContent;
		};
	} forEach _alldead;

	//--Trash all UAVs without fuel or dead--
	_allDeadUav = allUnitsUAV;
	{
		if(!alive _x || (fuel _x) < 0.01) then {
			deleteVehicle _x;
		};
	} forEach _allDeadUav;

	_allmissionObjects = allMissionObjects "";
    _delete = false;
    {
        _missionObject = _x;
        {
            if (_missionObject isKindOf _x) then {
                if (count(_missionObject nearEntities ["Man", 15]) < 1) then {deleteVehicle _missionObject; _delete = true};
            };
        } forEach _miscObjectTypes;

        if (_delete) exitWith {};
    } forEach _allmissionObjects;

	
	sleep 30;
};