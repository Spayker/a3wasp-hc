params ["_structure"];
private ["_side", "_index", "_killer", "_killer_uid", "_killer_name", "_side_killer",
"_teamkill", "_current", "_logik", "_bounty", "_type"];

_side = _structure getVariable "wf_side";
_index = _structure getVariable "wf_index";
_type = _structure getVariable "wf_structure_type";
_killer = _structure getVariable ["wf_instigator", objNull];
_killer_uid = "";

_structure setDammage 1;
[_structure] spawn WFSE_FNC_CreateDestructionEffect;

//--Determine if killer is in player squad--
if(!isPlayer _killer) then {
    _killer = leader (group _killer);
};

//--Notice about event and give bounty--
if (isPlayer _killer) then {
    _killer_uid = getPlayerUID _killer;
    _killer_name = name _killer;

    //--Insert data to DB--
    [_type, _side call WFCO_FNC_GetSideID, _killer_uid, _killer_name, time] spawn WFSE_FNC_InsertStructureKilled;

    //--Is teamkill?--
    _teamkill = if (side _killer == _side) then {true} else {false};
    _side_killer = side _killer;

    if (_teamkill) then {
    	["BuildingTeamkill", _killer_name, _killer_uid, _index] remoteExecCall ["WFCL_FNC_LocalizeMessage", _side];

    	["INFORMATION", format ["fn_BuildingKilled.sqf: [%1] [%2] has teamkilled a friendly structure [%3]",
    	    _killer_name, _killer_uid, _type]] call WFCO_FNC_LogContent;

        [format ["%1**%2** has teamkilled a friendly structure %3**%4** :boom:", _side_killer call WFCO_FNC_GetSideFLAG,
            _killer_name, _side call WFCO_FNC_GetSideFLAG, _type]] call WFDC_FNC_LogContent;
    } else {
        if (!isNull _killer) then {
            _bounty = switch (_type) do {
                        case ("Headquarters"):{15000};
                        case ("Barracks"):{3000};
                        case ("Light"):{4500};
                        case ("Heavy"):{7000};
                        case ("Aircraft"):{8000};
                        case ("CommandCenter"):{5000};
                        case ("ServicePoint"):{3000};
                        case ("AARadar"):{8000};
                        case ("ArtyRadar"):{8000};
                        default {3000};
                      };

            ["HeadHunterReceiveBounty", _killer_name, _bounty, _index, _side] remoteExecCall ["WFCL_FNC_LocalizeMessage",
                _side_killer];
				
			[_killer, score _killer + ceil(_bounty/100)] call WFSE_FNC_RequestChangeScore;
        };

        _killer_name = format [" by %1**%2**%3", _side_killer call WFCO_FNC_GetSideFLAG, _killer_name,
                (WFDC_SMILES # 0) # (floor random count (WFDC_SMILES # 0))];

        ["INFORMATION", format ["fn_BuildingKilled.sqf: [%1] Structure [%2] has been destroyed by [%3]", str _side,
                _type, _killer]] Call WFCO_FNC_LogContent;
        [format ["Structure %1**%2**:boom: has been destroyed%3", _side call WFCO_FNC_GetSideFLAG, _type,
                _killer_name]] call WFDC_FNC_LogContent;
    };
};

//--Decrement buildings limit--
    _logik = (_side) Call WFCO_FNC_GetSideLogic;

    if (_type == "Headquarters") then {
        _mhqs = (_side) Call WFCO_FNC_GetSideHQ;
        _mhqs = _mhqs - [_structure];

        _logik setVariable ["wf_hq", _mhqs, true]
    };

    if!(isNil '_index') then {
        if (_index > 0) then {
    	_current = _logik getVariable "wf_structures_live";
    	_current set [_index - 1, (_current # (_index-1)) - 1];
            _logik setVariable ["wf_structures_live", _current, true]
    };

    _logik setVariable ["wf_structures", (_logik getVariable "wf_structures") - [_structure, objNull], true];
    [_side, "Destroyed", ["Base", _structure]] remoteExecCall ["WFSE_FNC_SideMessage", 2]
};


[_structure] spawn {
    params ['_structure'];
sleep WF_DELETE_RUINS_LAT;
deleteVehicle _structure
}

