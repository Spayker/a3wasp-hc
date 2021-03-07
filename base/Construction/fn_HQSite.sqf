params ["_type", "_side", "_position", "_direction", "_index"];
private ["_areas","_deployed","_grp","_HQ","_HQName","_logic","_logik","_MHQ","_near","_sideText","_site","_update",
"_env", "_siteMaxHealth"];

_sideText = _side;
_sideID = (_side) Call WFCO_FNC_GetSideID;
_logik = (_side) Call WFCO_FNC_GetSideLogic;

if (_position isEqualType objNull) then {_position = position _position};

/* Handle the LAG. */
waitUntil {!(_logik getVariable "wf_hqinuse")};
_logik setVariable ["wf_hqinuse", true];

_HQ = (_side) Call WFCO_FNC_GetSideHQ;
_deployed = (_side) Call WFCO_FNC_GetSideHQDeployStatus;
_hqDesc = (missionNamespace getVariable Format ["WF_%1STRUCTUREDESCRIPTIONS", str _side]) # _index;
_env = (missionNamespace getVariable Format ["WF_%1STRUCTUREENV", str _side]) # _index;
_siteMaxHealth = (missionNamespace getVariable format ["WF_%1STRUCTUREMAXHEALTH",str _side]) # _index;
_dmgr = (missionNamespace getVariable format["WF_%1STRUCTUREDMGREDUCER",str _side]) # _index;

if (!_deployed) then {
	_HQ setPosATL [1,1,1];

	_site = nil;
	_env = [_position, _direction, _env] call BIS_fnc_ObjectsMapper;
	_nv = [];

	//--Compute _site first--
	{
		if((typeOf _x) == _type) then {
			_site = _x;
			_site enableSimulationGlobal false;
			_sPos = getPosATL _site;
			_sPos set [2, 0];
			_site setPosATL _sPos;
			_site lock true;
			_site setVariable ["wf_side", _side];
			_site setVariable ["wf_structure_type", "Headquarters"];
			_site setVariable ["wf_structure_desc", _hqDesc, true];
			_site setVariable ["wf_structure_master", _site];
		};
	} forEach _env;

	{
		if((typeOf _x) != _type) then {
			_x setVectorUp surfaceNormal position _x;
			_nv pushBack _x;
		};
	} forEach _env;

	_site setVariable ["_env", _nv];
	_site setVariable ["wf_site_maxhealth", _siteMaxHealth];
    _site setVariable ["wf_site_health", _siteMaxHealth, true];    
    _site setVariable ["wf_reducer", _dmgr # 0];
	_site setVariable ["wf_hq", true];
	_site setVariable ["wf_index", _index];
	
	[_site, "Headquarters"] remoteExec ["WFCL_FNC_addBaseBuildingRepAction", _side, true];

	_logik setVariable ['wf_hq_deployed', true, true];
	_logik setVariable ["wf_hq", _site, true];

	[_site,true,_sideID] remoteExec ["WFCL_fnc_initBaseStructure", 0, true];

	[_side,"Deployed", ["Base", _site]] Spawn WFSE_FNC_SideMessage;

    //--Avoid notice about building damage for first 5 seconds after construction complete--
    _site setVariable ["wf_lastnotice", time + 5];
	_site addEventHandler ["Hit", {
        params ["_unit"];
        [_unit] call WFSE_FNC_BuildingDamaged;
    }];

    _site addEventHandler ["HandleDamage", {
        _this call WFCO_FNC_BuildingHandleDamage;
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
			_logic = _grp createUnit ["Logic",[0,0,0],[],0,"NONE"];
			_logic setVariable ["DefenseTeam", createGroup [_side, true]];
            (_logic getVariable "DefenseTeam") setVariable ["wf_persistent", true];
	        _logic setVariable ["weapons",missionNamespace getVariable "WF_C_BASE_DEFENSE_MAX"];
			[_logic, _position,_side,_logik,_areas] remoteExecCall ["WFCL_FNC_RequestBaseArea",_side];
		};
	};

	["INFORMATION", Format ["Construction_HQSite.sqf: [%1] MHQ has been deployed.", _sideText]] Call WFCO_FNC_LogContent;

	deleteVehicle _HQ;
} else {
	_position = getPosATL _HQ;
	{
		if(_x != _HQ) then {
			deleteVehicle _x;
		};
	}	forEach (_HQ getVariable "_env");

	[_position] Call WFCO_FNC_BrokeTerObjsAround;

	_direction = getDir _HQ;
	_HQName = missionNamespace getVariable Format["WF_%1MHQNAME",_sideText];

	_MHQ = [_HQName, _position, _sideID, _direction, true, false] Call WFCO_FNC_CreateVehicle;

	_MHQ setVelocity [0,0,-1];
	_MHQ setVariable ["wf_side", _side];
	_MHQ setVariable ["wf_trashable", false];
	_MHQ setVariable ["wf_structure_type", "Headquarters"];
	_MHQ setVariable ["wf_structure_desc", _hqDesc];
	_MHQ addMPEventHandler ["MPHit",{_this Spawn WFSE_FNC_BuildingDamaged}];
	_MHQ addMPEventHandler ['MPKilled', {_this Spawn WFSE_FNC_OnHQKilled}]; //--- Killed EH fires localy, this is the server.
	_logik setVariable ["wf_hq", _MHQ, true];
	_logik setVariable ['wf_hq_deployed', false, true];
	[_side,"Mobilized", ["Base", _MHQ]] Spawn WFSE_FNC_SideMessage;

	if (isMultiplayer) then {
		[_mhq] remoteExecCall ["WFCL_FNC_setHqLockAndUnlockActions", _side];
	};

	["INFORMATION", Format ["Construction_HQSite.sqf: [%1] MHQ has been mobilized.", _sideText]] Call WFCO_FNC_LogContent;
	_MHQ addAction [localize "STR_WF_Unlock_MHQ",{call WFCL_fnc_toggleLock}, [], 95, false, true, '', 'alive _target && (locked _target == 2)',10];
    _MHQ addAction [localize "STR_WF_Lock_MHQ",{call WFCL_fnc_toggleLock}, [], 94, false, true, '', 'alive _target && (locked _target == 0)',10];
	deleteVehicle _HQ;
};

/* Handle the LAG. */
_logik setVariable ["wf_hqinuse", false];