params ["_building", "_unitType", "_side", "_team"];
Private ["_building","_built","_config","_crew","_dir","_distance","_factoryPosition","_factoryType","_index","_vehiSlots","_longest","_position","_queu","_queu2","_ret","_side","_sideID","_sideText","_soldier","_team","_turrets","_type","_unitType","_vehicle","_waitTime"];

_sideID = (_side) Call WFCO_FNC_GetSideID;
_sideText = str _side;

if !(alive _building) exitWith {["INFORMATION", Format ["fn_resBuyUnit.sqf: Unit [%1] construction has been stopped due to factory destruction.", _unitType]] Call WFCO_FNC_LogContent};

["INFORMATION", Format ["fn_resBuyUnit.sqf: [%1] Team has purchased a [%1] unit.",_team, _unitType]] Call WFCO_FNC_LogContent;

_type = typeOf _building;

_index = (missionNamespace getVariable Format ["WF_%1STRUCTURENAMES", _sideText]) find _type;
_distance = (missionNamespace getVariable Format ["WF_%1STRUCTUREDISTANCES", _sideText]) # _index;
_factoryType = (missionNamespace getVariable Format ["WF_%1STRUCTURES", _sideText]) # _index;

_waitTime = (missionNamespace getVariable _unitType) # QUERYUNITTIME;
_direction = (missionNamespace getVariable Format["WF_%1STRUCTUREDIRECTIONS", str _side]) # _index;
_position = [getPos _building, _distance, getDir _building + _direction] Call WFCO_FNC_GetPositionFrom;
_longest = missionNamespace getVariable Format ["WF_LONGEST%1BUILDTIME",_factoryType];

if !(alive _building) exitWith {["INFORMATION", Format ["fn_resBuyUnit.sqf: Unit [%1] construction has been stopped due to factory destruction.", _unitType]] Call WFCO_FNC_LogContent};

_factoryPosition = getPosATL _building;
_dir = -((((_position # 1) - (_factoryPosition # 1)) atan2 ((_position # 0) - (_factoryPosition # 0))) - 90);

if (_unitType isKindOf "Man") then {
    [_side, _unitType, _position, _team, _dir] call WFCO_FNC_CreateUnitsForResBases
} else {
    _special = if (_unitType isKindOf "Air") then {"FLY"} else {"NONE"};
    [_side, _unitType, _position, _team, _dir, _special] call WFCO_FNC_CreateUnitsForResBases
}