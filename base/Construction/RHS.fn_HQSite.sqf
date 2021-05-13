params ["_type", "_side", "_position", "_direction"];

[_type, _side, _position, _direction] spawn {
    params ["_type", "_side", "_position", "_direction"];
private ["_areas","_deployed","_grp","_HQ","_HQName","_logic","_logik","_MHQ","_near","_sideText","_site","_update",
"_siteMaxHealth","_dmgr","_index"];

_sideText = _side;
_sideID = (_side) Call WFCO_FNC_GetSideID;
_logik = (_side) Call WFCO_FNC_GetSideLogic;

if (_position isEqualType objNull) then {_position = position _position};
_index = 0;
_siteMaxHealth = (missionNamespace getVariable format ["WF_%1STRUCTUREMAXHEALTH",str _side]) # _index;
_dmgr = (missionNamespace getVariable format["WF_%1STRUCTUREDMGREDUCER",str _side]) # _index;

/* Handle the LAG. */
_logik setVariable ["wf_hqinuse", true];

_mhqs = (_side) Call WFCO_FNC_GetSideHQ;
_HQ = [_position, _mhqs] call WFCO_FNC_GetClosestEntity;

_deployed = [_side, _HQ] Call WFCO_FNC_GetSideHQDeployStatus;

if (!_deployed) then {
    _mhqs = _mhqs - [_HQ];
    deleteVehicle _HQ;
	
    _site = createVehicle [_type, [_position # 0, _position # 1, -0.6], [], 0, "NONE"];
	_site setDir _direction;
    _site setVectorUp surfaceNormal position _site;
	_site setVariable ["wf_side", _side];
    _site setVariable ["wf_structure_type", "Headquarters", true];
	_site setVariable ["wf_site_maxhealth", _siteMaxHealth];
    _site setVariable ["wf_site_health", _siteMaxHealth, true];
    _site setVariable ["wf_reducer", _dmgr # 0];
    _site setVariable ["wf_hq", true];
    _site setVariable ["wf_index", _index];
	
	[_site, "Headquarters"] remoteExec ["WFCL_FNC_addBaseBuildingRepAction", _side, true];

    _site setVariable ['wf_hq_deployed', true, true];

    _mhqs pushBackUnique _site;
    _logik setVariable ["wf_hq", _mhqs, true];
	
	[_site,true,_sideID] remoteExec ["WFCL_fnc_initBaseStructure", 0, true];
	
        [_side,"Deployed", ["Base", _site]] remoteExecCall ["WFSE_FNC_SideMessage", 2];

	_site addEventHandler ["Hit", {
        params ["_unit"];
            [_unit] call WFHC_FNC_BuildingDamaged;
    }];

    _site addEventHandler ["HandleDamage", {
            _this call WFHC_FNC_BuildingHandleDamage;
        false;
    }];
	
	//--- base area limits.
	if ((missionNamespace getVariable "WF_C_BASE_AREA") > 0) then {
		_update = true;
		_areas = _logik getVariable "wf_basearea";
		_near = [_position,_areas] Call WFCO_FNC_GetClosestEntity;
		if (!isNull _near) then {
			if (_near distance _position < ((missionNamespace getVariable "WF_C_BASE_AREA_RANGE") + (missionNamespace getVariable "WF_C_BASE_HQ_BUILD_RANGE"))) then {_update = false};
		};
		if (_update) then {
			_grp = createGroup sideLogic;
            _logic = _grp createUnit ["Logic",_position,[],0,"NONE"];
			_logic setVariable ["DefenseTeam", createGroup [_side, true]];
            (_logic getVariable "DefenseTeam") setVariable ["wf_persistent", true];
	        _logic setVariable ["weapons",missionNamespace getVariable "WF_C_BASE_DEFENSE_MAX_AI"];
            [_logic, _side,_logik,_areas] remoteExecCall ["WFCL_FNC_RequestBaseArea",_side, true];
		};
	};
	
	["INFORMATION", Format ["Construction_HQSite.sqf: [%1] MHQ has been deployed.", _sideText]] Call WFCO_FNC_LogContent;
	};


/* Handle the LAG. */
_logik setVariable ["wf_hqinuse", false];}

