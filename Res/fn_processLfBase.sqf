params["_building", "_side", "_type", "_facIndex"];
private["_side", "_sideText", "_structurePos", "_resTemplates", "_resTemplatesTypes", "_lightTemplate"];

_sideText = str _side;

_dmgr = (missionNamespace getVariable format["WF_%1STRUCTUREDMGREDUCER",str _side]) # _facIndex;
_siteMaxHealth = (missionNamespace getVariable format ["WF_%1STRUCTUREMAXHEALTH",str _side]) # _facIndex;

_building setVariable ["wf_side", _side, true];
_building setVariable ["wf_structure_type", _type, true];
_building setVariable ["wf_site_maxhealth", _siteMaxHealth, true];
_building setVariable ["wf_site_health", _siteMaxHealth, true];
_building setVariable ["wf_reducer", _dmgr # 0, true];
_building setVariable ["wf_index", _facIndex, true];

_building addEventHandler ["HandleDamage", {
    _this call WFHC_FNC_BuildingHandleDamage;
    false
}];

_groups_max = 2;
_units = [];
_unit_vehicles = [];
_unitTemplates = [
    [Format ["Motorized_%1", floor random 10]],
    [Format ["Motorized_%1", floor random 10]]
];

_k = 0;
for '_j' from 0 to (_groups_max - 1) do {
    _units pushBack (_unitTemplates # _k);
    if(_k <= (count _unitTemplates) - 1) then {
        _k = _k + 1;
    } else {
        _k = 0;
    };
};

{
	if (!isNil {missionNamespace getVariable Format ["WF_%1_GROUPS_%2", _side, _x # 0]}) then {
	    _unit_vehicles pushBack (_x # 0)
	}
} forEach _units;

_total_vehicles = count _unit_vehicles;
if ((_total_vehicles) == 0) exitWith {[]};
if (_total_vehicles > 1) then {_unit_vehicles = (_unit_vehicles) Call WFCO_FNC_ArrayShuffle};

_final = [];
for '_j' from 0 to (_total_vehicles - 1) do { _final pushBack (_unit_vehicles # _j) };

_contents = [];
{
	_get = missionNamespace getVariable Format ["WF_%1_GROUPS_%2", _side, _x];
	if !(isNil '_get') then {_contents pushBack (_get select floor(random count _get))}
} forEach _final;

_resTemplates = _contents;
_lightTemplate = [];
_o = 0;

{
	_lightTemplate pushBack _o ;
	_o = _o + 1
} forEach _resTemplates;

WF_Logic setVariable [Format["%1%2TeamBaseLightPatrol%3",_sideText, _facIndex, 1], false];

while { alive _building } do {
    _patrolTeamAlive = WF_Logic getVariable Format ["%1%2TeamBaseLightPatrol%3", _sideText, _facIndex, 1];
	if (!_patrolTeamAlive) then {
        _ranTemp = _lightTemplate # (random((count _lightTemplate)-1));
        _templateToUse = _resTemplates # _ranTemp;
        [_side, _templateToUse, _building, Format ["%1%2TeamBaseLightPatrol%3", _sideText, _facIndex, 1]] spawn WFHC_FNC_processResTeam;
        WF_Logic setVariable [Format ["%1%2TeamBaseLightPatrol%3", _sideText, _facIndex, 1], true]
	};
	sleep 600
}