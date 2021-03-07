//*****************************************************************************************
//Description: Creates a small construction site.
//*****************************************************************************************
params ["_type", "_side", "_position", "_direction", "_index", "_playerUID"];
private ["_constructed","_group","_logik","_nearLogic","_objects","_rlType","_sideID","_site","_siteName","_ruins",
"_startTime","_structuresNames","_time","_timeNextUpdate","_xPos","_dmgblIndex","_siteMaxHealth",
"_WF_SMALL_SITE_1_OBJECTS", "_WF_SMALL_SITE_2_OBJECTS", "_WF_SMALL_SITE_3_OBJECTS"];

#include "fn_SmallSiteObjects.sqf";

_logik = (_side) call WFCO_FNC_GetSideLogic;
_sideID = (_side) call WFCO_FNC_GetSideID;

_time = ((missionNamespace getVariable format ["WF_%1STRUCTURETIMES",str _side]) # _index) / 2;

_siteName = missionNamespace getVariable format["WF_%1CONSTRUCTIONSITE",str _side];
_siteDesc = (missionNamespace getVariable format ["WF_%1STRUCTUREDESCRIPTIONS",str _side]) # _index;
_siteMaxHealth = (missionNamespace getVariable format ["WF_%1STRUCTUREMAXHEALTH",str _side]) # _index;

_env = (missionNamespace getVariable format["WF_%1STRUCTUREENV",str _side]) # _index;
_dmgbl = (missionNamespace getVariable format["WF_%1STRUCTUREDMGABLE",str _side]) # _index;
_dmgr = (missionNamespace getVariable format["WF_%1STRUCTUREDMGREDUCER",str _side]) # _index;
_smpl = (missionNamespace getVariable format["WF_%1STRUCTURESMPL",str _side]) # _index;
_rlType = (missionNamespace getVariable format["WF_%1STRUCTURES",str _side]) # _index;

_structuresNames = missionNamespace getVariable format ['WF_%1STRUCTURENAMES',str _side];

_startTime = time;
_timeNextUpdate = _startTime + _time;

_constructed = ([_position,_direction,_WF_SMALL_SITE_1_OBJECTS] call WFSE_FNC_CreateObjectsFromArray);

//--- Create the logic.
(createGroup sideLogic) createUnit ["LocationArea_F",_position,[],0,"NONE"];

_nearLogic = objNull;
if ((missionNamespace getVariable "WF_C_STRUCTURES_CONSTRUCTION_MODE") == 0) then {
	//--- Grab the logic.
	_nearLogic = _position nearEntities [["LocationArea_F"],15];
	_nearLogic = [_position, _nearLogic] call WFCO_FNC_GetClosestEntity;

	if (isNull _nearLogic) exitWith {};

	//--- Position the logic.
	_nearLogic setPosATL _position;

	_nearLogic setVariable ["WF_B_Type", _rlType];

	waitUntil {time >= _timeNextUpdate};
	_timeNextUpdate = _startTime + _time * 2;
} else {
	//--- Grab the logic.
	_nearLogic = _position nearEntities [["LocationArea_F"],15];
	_nearLogic = [_position, _nearLogic] call WFCO_FNC_GetClosestEntity;

	if (isNull _nearLogic) exitWith {};

	//--- Position the logic.
	_nearLogic setPosATL _position;

	//--- Instanciate the logic.
	_nearLogic setVariable ["WF_B_Completion", 0];
	_nearLogic setVariable ["WF_B_CompletionRatio", 0.6];
	_nearLogic setVariable ["WF_B_Direction", _direction];
	_nearLogic setVariable ["WF_B_Position", _position];
	_nearLogic setVariable ["WF_B_Repair", false];
	_nearLogic setVariable ["WF_B_Type", _rlType];

	//--- Add the logic to the list.
	_logik setVariable ["wf_structures_logic", (_logik getVariable "wf_structures_logic") + [_nearLogic]];

	//--- Awaits for 33% of completion.
	while {true} do {
		sleep 1;
		if ((_nearLogic getVariable "WF_B_Completion") >= 33.33) exitWith {};
	};
};

_constructed = _constructed + ([_position,_direction,_WF_SMALL_SITE_2_OBJECTS] call WFSE_FNC_CreateObjectsFromArray);

if ((missionNamespace getVariable "WF_C_STRUCTURES_CONSTRUCTION_MODE") == 0) then {
	waitUntil {time >= _timeNextUpdate};
	_timeNextUpdate = _startTime + _time * 3;
} else {
	//--- Awaits for 66%
	while {true} do {
		sleep 1;
		if ((_nearLogic getVariable "WF_B_Completion") >= 66.66) exitWith {};
	};
};

_constructed = _constructed + ([_position,_direction,_WF_SMALL_SITE_3_OBJECTS] call WFSE_FNC_CreateObjectsFromArray);

if ((missionNamespace getVariable "WF_C_STRUCTURES_CONSTRUCTION_MODE") == 0) then {
	waitUntil { time >= _timeNextUpdate };

	if !(isNull _nearLogic) then {
		_group = group _nearLogic;
		deleteVehicle _nearLogic;
		deleteGroup _group;
	};
} else {
	//--- Awaits for 100%
	while {true} do {
		sleep 1;
		if ((_nearLogic getVariable "WF_B_Completion") >= 100) exitWith {};
	};

	//--- Remove the logic from the list since it's built. Add it back if destroyed.
	_logik setVariable ["wf_structures_logic", (_logik getVariable "wf_structures_logic") - [_nearLogic]];
};

if(!isNil "_constructed") then {
	{
	    if!(isNull _x) then {
	        deleteVehicle _x
	    };
	} forEach _constructed;
};

_site = nil;

_dircor = (missionNamespace getVariable format ["WF_%1STRUCTUREDIRECTIONS",str _side]) # (_structuresNames find _type);

_env = [_position, _direction - _dircor, _env] call BIS_fnc_ObjectsMapper;
_nv = [];

//--Compute _site first--
{
    _x enableSimulationGlobal false;
	_x setVectorUp surfaceNormal position _x;
	_x lock true;

	_xPos = getPosATL _x;
    _xPos set [2, 0];
    _x setPosATL _xPos;

	if((typeOf _x) == _type) then {
		_site = _x;
		_site setVariable ["wf_structure_type", _rlType];
		_site setVariable ["wf_site_maxhealth", _siteMaxHealth];
		_site setVariable ["wf_site_health", _siteMaxHealth, true];
		_site setVariable ["wf_structure_desc", _siteDesc, true];
		_site setVariable ["wf_index", _index];
		_site setVariable ["wf_dmgbl", _dmgbl];
		
		[_site, _rlType] remoteExec ["WFCL_FNC_addBaseBuildingRepAction", _side, true];
	};
} forEach _env;

if!(isNil "_site") then {
    //--Check damage of new factory. Exit if it destroyed and give back supplies--BEGIN-------------------------------//
    if((damage _site) == 1) then {
        //--removeAllEH from master and env objects. Destroy env objects--
        {
            _x removeAllEventHandlers "Hit";
            _x removeAllEventHandlers "HandleDamage";
            _x setDamage 1;

            //--Create explosion, fire and smoke--
            if((typeOf _x) in _dmgbl) then {
                [_x] spawn WFSE_FNC_CreateDestructionEffect;
            };
        } forEach _env;

        [_site] spawn WFSE_FNC_CreateDestructionEffect;

        //--- Decrement building limit.
        if (_index != -1) then {
        	_current = _logik getVariable "wf_structures_live";
        	_current set [_index - 1, (_current # (_index-1)) - 1];
        	_logik setVariable ["wf_structures_live", _current, true];
        };

        _logik setVariable ["wf_structures", (_logik getVariable "wf_structures") - [_site, objNull], true];

        [_side, "Destroyed", ["Base", _site]] spawn WFSE_FNC_SideMessage;
        //--Give back team supply--
        _price = (missionNamespace getVariable format ["WF_%1STRUCTURECOSTS",str _side]) # (_structuresNames find _type);
        [_side, _price] call WFCO_FNC_ChangeSideSupply;
        _site = nil;
        //--Delete all ruins--
        sleep WF_DELETE_RUINS_LAT;
        //--Get attached objects and remove each of them--
        {
        	deleteVehicle _x;
        } forEach _env;

        _ruins = nearestObjects [_position, ["ruins"], 25];

        //--Delete ruins--
        {
        	deleteVehicle _x;
        } forEach _ruins;

        terminate _thisScript;
    };
    //--Check damage of new factory--END------------------------------------------------------------------------------//

	//--Initialize dammagable and simple objects--
	{
		_typeOf = typeOf _x;

        _dmgblIndex = _dmgbl find _typeOf;
		if(_dmgblIndex > -1) then {
		    _x setDamage 0;
		    _x setVariable ["wf_structure_master", _site];
        	_x setVariable ["wf_side", _side];
        	_x setVariable ["wf_reducer", _dmgr # _dmgblIndex];

            //--Avoid notice about building damage for first 5 seconds after construction complete--
            _x setVariable ["wf_lastnotice", time + 5];
        	_x addEventHandler ["Hit", {
        	    params ["_unit"];
        	    [_unit getVariable "wf_structure_master"] call WFSE_FNC_BuildingDamaged;
        	}];

        	_x addEventHandler ["HandleDamage", {
        	    _this call WFCO_FNC_BuildingHandleDamage;
        	    false;
        	}];
        };

		if(_typeOf in _smpl) then {
			_posASL = getPosASL _x;
			_posASL set[2, ((_posASL # 2)) - 10000];
			_posATL = getPosATL _x;
			_posATL set[2, 0];
			_smplDir = getDir _x;
			_smplObj = createSimpleObject [_typeOf, _posASL];
			_smplObj setPosATL _posATL;
			_smplObj setDir _smplDir;
			_smplObj setVectorUp surfaceNormal position _smplObj;
			_nv pushBack _smplObj;

			deleteVehicle _x;
		} else {
            if(_typeOf != _type) then {
                _nv pushBack _x;
            };
		};
	} forEach _env;

	_site setVariable ["wf_env", _nv];

	[_side, "Constructed", ["Base", _site]] spawn WFSE_FNC_SideMessage;

    _logik setVariable ["wf_structures", (_logik getVariable "wf_structures") + [_site], true];
    [_site,false,_sideID] remoteExec ["WFCL_fnc_initBaseStructure", 0, true];

    ["INFORMATION", format ["fn_SmallSite.sqf: [%1] Structure [%2] has been constructed.", str _side, _type]] call WFCO_FNC_LogContent;

	//--- Base Patrols.
	if (_rlType == "Barracks" && (missionNamespace getVariable "WF_C_BASE_PATROLS_INFANTRY") > 0) then {
		[_site, _side] spawn WFSE_fnc_createBasePatrol;
		["INFORMATION", format ["fn_SmallSite.sqf: [%1] Base patrol has been triggered upon Barrack creation.", str _side]] call WFCO_FNC_LogContent;
	};
};