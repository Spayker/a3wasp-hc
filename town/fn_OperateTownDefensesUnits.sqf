/*
	Oeprate the defenses in a town, spawn or despawn.
	 Parameters:
		- Town.
		- Side.
		- Action ("spawn"/"remove").
*/
params ["_town", "_side", "_action"];
private ["_defense","_crewUnits","_spawn","_units","_sideID","_publicFor"];

_sideID = (_side) call WFCO_FNC_GetSideID;

if (_sideID != WF_C_GUER_ID) exitWith {};

switch (_action) do {
	case "spawn": {
	    _allDefences = _town getVariable ["wf_town_defenses", []];
		if(count _allDefences > 0) then {
		    _townDefenses = [_town, _side, _sideID, _allDefences] call WFHC_FNC_ManageTownDefenses;
            //--- Man the defenses.
            _group = createGroup [_side, true];
            _defences = [];
            {
                if!(isNil '_x') then {
                    _defense = _x # 3;
                    if!(isNil '_defense') then {
                        if (alive _defense) then {
                            if !(alive gunner _defense) then { //--- Make sure that the defense gunner is null or dead.
                                _defences pushBack _defense;
                            }
                        }
                    }
                }
            } forEach (_townDefenses);
			[_side, _group, _defences] call WFHC_FNC_DelegateAIStaticDefence;
            ["INFORMATION", format ["fn_OperateTownDefensesUnits.sqf : Town [%1] defenses were manned for [%2] defenses on [%3].", _town getVariable "name", count (_town getVariable "wf_town_defenses"),_side]] call WFCO_FNC_LogContent;
        } else {
            ["WARNING", format ["fn_OperateTownDefensesUnits.sqf : No defenses found for town %1", _town getVariable "name"]] call WFCO_FNC_LogContent;
        }
	};
	case "remove": {
		//--- De-man the defenses.
		{
		    if!(isNil '_x') then {
                _defense = _x # 3;
                if !(isNil '_defense') then {
                    _crewUnits = _defense getVariable ["crewUnits", []];
                        _unit = gunner _defense;
                        if !(isNull _unit) then { //--- Make sure that we do not remove a player's unit.
                            if (alive _unit) then {
                                if (isNil {(group _unit) getVariable "wf_funds"}) then { _unit setPos (_x # 1);	deleteVehicle _unit };
                            } else {
                                _unit setPos (_x # 1); deleteVehicle _unit;
                            };
                        };
                    //--Remove town static defence gunners--
                    {
                        //--If a unit is in a vehicle use deleteVehicleCrew, otherwise deleteVehicle--
                        if (!isNull (objectParent _x)) then {
                            (objectParent _x) deleteVehicleCrew _x
                        } else {
                            deleteVehicle _x
                        }
                    } forEach _crewUnits;

                    _defense setVariable ["crewUnits", nil, true];
                    deleteVehicle _defense
                }
		    }
		} forEach (_town getVariable "wf_town_defenses");

		["INFORMATION", format ["fn_OperateTownDefensesUnits.sqf : Town [%1] defenses units were removed for [%2] defenses.", _town getVariable "name", count (_town getVariable "wf_town_defenses")]] call WFCO_FNC_LogContent;
	};
};