//*****************************************************************************************
//Description: Creates a small construction site.
//*****************************************************************************************
params ["_type", "_side", "_position", "_direction", "_index", "_playerUID", ["_isStartBase", false]];


[_type, _side, _position, _direction, _index, _playerUID, _isStartBase] spawn {
    params ["_type", "_side", "_position", "_direction", "_index", "_playerUID", ["_isStartBase", false]];
    private ["_construct","_constructed","_group","_logik","_nearLogic","_rlType","_sideID","_site","_siteName",
    "_startTime","_structures","_structuresNames","_time","_timeNextUpdate","_siteMaxHealth","_dmgr"];
_logik = (_side) Call WFCO_FNC_GetSideLogic;
_sideID = (_side) Call WFCO_FNC_GetSideID;

_time = ((missionNamespace getVariable Format ["WF_%1STRUCTURETIMES",str _side]) # _index) / 2;
if (_isStartBase) then { _time = 1 };

_siteName = missionNamespace getVariable Format["WF_%1CONSTRUCTIONSITE",str _side];

_structures = missionNamespace getVariable Format ['WF_%1STRUCTURES',str _side];
_structuresNames = missionNamespace getVariable Format ['WF_%1STRUCTURENAMES',str _side];
_dmgr = (missionNamespace getVariable format["WF_%1STRUCTUREDMGREDUCER",str _side]) # _index;
_siteMaxHealth = (missionNamespace getVariable format ["WF_%1STRUCTUREMAXHEALTH",str _side]) # _index;
_rlType = _structures select (_structuresNames find _type);

_startTime = time;
_timeNextUpdate = _startTime + _time;

    _constructed = ([_position,_direction,WF_SMALL_SITE_1_OBJECTS] call WFHC_FNC_CreateObjectsFromArray);

waitUntil {time >= _timeNextUpdate};
_timeNextUpdate = _startTime + _time * 2;

    _constructed = _constructed + ([_position,_direction,WF_SMALL_SITE_2_OBJECTS] Call WFHC_FNC_CreateObjectsFromArray);

if(!isNil "_constructed")then{
	{
	    if!(isNull _x)then{
	        deleteVehicle _x
	    };
	} forEach _constructed;
};

if(_type == 'Base_WarfareBUAVterminal') then {
    _position = [_position # 0, _position # 1, -0.1]
} else {
    _position = [_position # 0, _position # 1, -0.65]
};

_site = createVehicle [_type, _position, [], 0, "NONE"];
_site setDir _direction;
_site setVectorUp surfaceNormal position _site;
_site setVariable ["wf_side", _side];
_site setVariable ["wf_structure_type", _rlType, true];
_site setVariable ["wf_site_maxhealth", _siteMaxHealth];
_site setVariable ["wf_site_health", _siteMaxHealth, true];
_site setVariable ["wf_reducer", _dmgr # 0];
_site setVariable ["wf_index", _index];

[_site, _rlType] remoteExec ["WFCL_FNC_addBaseBuildingRepAction", _side, true];

if!(_isStartBase) then {
if(missionNamespace getVariable[format["WF_AutoWallConstructingEnabled_%1", _playerUID], WF_AutoWallConstructingEnabled]) then {
            _defenses = [_site, missionNamespace getVariable format ["WF_NEURODEF_%1_WALLS", _rlType]] call WFHC_FNC_CreateDefenseTemplate;
	_site setVariable ["WF_Walls", _defenses];
};

        [_side, "Constructed", ["Base", _site]] remoteExecCall ["WFSE_FNC_SideMessage", 2];

    //--- Base Patrols.
    if (_rlType == "Barracks" && (missionNamespace getVariable "WF_C_BASE_PATROLS_INFANTRY") > 0) then {
        	[_site, _side] spawn WFHC_fnc_createBasePatrol;
    	["INFORMATION", Format ["fn_SmallSite.sqf: [%1] Base patrol has been triggered upon Barrack creation.", str _side]] Call WFCO_FNC_LogContent;
    }
};

if (!isNull _site) then {
	_logik setVariable ["wf_structures", (_logik getVariable "wf_structures") + [_site], true];
	[_site,false,_sideID] remoteExec ["WFCL_fnc_initBaseStructure", 0, true];
	
    _site addEventHandler ["Hit", {
        params ["_unit"];
            [_unit] call WFHC_FNC_BuildingDamaged;
    }];

    _site addEventHandler ["HandleDamage", {
            _this call WFHC_FNC_BuildingHandleDamage;
        false;
    }];
	
	["INFORMATION", Format ["fn_SmallSite.sqf: [%1] Structure [%2] has been constructed.", str _side, _type]] Call WFCO_FNC_LogContent;
};
}
