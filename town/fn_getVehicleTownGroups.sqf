/*
	Return a list of groups to spawn in a town.
	 Parameters:
		- Town Entity.
		- Side.
*/

params["_town", "_side"];
private ["_get","_groups_max","_current_light_upgrade","_current_heavy_upgrade","_town_airactive","_units",
            "_side","_sv","_town","_unitTemplateCount","_randomSelectedTemplate","_unitTemplates",
            "_contents","_final","_startingSupplyValue","_campsCount"];

_sv = _town getVariable "supplyValue";
_town_airactive = _town getVariable "wf_active_air";
_startingSupplyValue = _town getVariable "startingSupplyValue";
_townDefendersSpeciality = _town getVariable ["townDefendersSpeciality", []];

_units = [];
_unitTemplates = [];

_current_light_upgrade = 0;
_current_heavy_upgrade = 0;
_current_aa_light_upgrade = floor random 2;
_current_aa_heavy_upgrade = 0;
_current_air_upgrade = 0;

_groups_max = 2;
_campsCount = count (_town getVariable "camps");
if(_campsCount > 0) then { _groups_max = _campsCount };

if (_side != resistance) then {
    _upgrades = (_side) Call WFCO_FNC_GetSideUpgrades;
    _current_light_upgrade = _upgrades # WF_UP_LIGHT;
    _current_heavy_upgrade = _upgrades # WF_UP_HEAVY;
    _current_air_upgrade = _upgrades # WF_UP_AIR;

    _unitsCoef = missionNamespace getVariable "WF_C_TOWNS_UNITS_COEF";
    if (_unitsCoef == 0) then { _unitsCoef = 1 };
    _groups_max = round(_groups_max * _unitsCoef);
    if(_sv == _startingSupplyValue) then { _groups_max = 1; };
} else {
    _sv = _town getVariable "maxSupplyValue";
    _groups_max = round(_groups_max * (missionNamespace getVariable "WF_C_TOWNS_UNITS_DEFENDER_COEF"));
    _current_light_upgrade = floor random 8; //--Random real (floating point) value from 0 (inclusive) to x (not inclusive)--
    _current_heavy_upgrade = floor random 3;
    _current_air_upgrade = floor random 5;
};

if (count _townDefendersSpeciality > 0) then {
    _vehicleSpeciality = _townDefendersSpeciality # 1;
    _vehicleGroupAmount = _vehicleSpeciality # 0;
    _vehicleQuality = _vehicleSpeciality # 1;
    _groups_max = _vehicleGroupAmount;

    switch (_vehicleQuality) do {
        case 'light':{ _sv = 50 };
        case 'medium':{ _sv = 80 };
        case 'heavy':{ _sv = 120 };
    }
};

switch (true) do {

	case (_sv >= 10 && _sv < 20): {
		_unitTemplates = [
					[Format ["Motorized_%1", _current_light_upgrade]]
				 ];
	};
	case (_sv >= 20 && _sv < 40): {
		_unitTemplates = [
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["AA_Light_%1", _current_heavy_upgrade]]
				];

	};
	case (_sv >= 40 && _sv <= 50): {
		_unitTemplates = [
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["AA_Light_%1", _current_aa_light_upgrade]]
				];

	};
	case (_sv > 50 && _sv < 65): {
		_unitTemplates = [
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["AA_Light_%1", _current_aa_light_upgrade]]
				];

	};
	case (_sv >= 65 && _sv < 80): {
		_unitTemplates = [
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Motorized_%1", _current_light_upgrade]],
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["AA_Heavy_%1", _current_aa_light_upgrade]]
				];

	};
	case (_sv >= 80 && _sv < 100): {
		_unitTemplates = [
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["Mechanized_%1", _current_heavy_upgrade]],
					[Format ["AA_Heavy_%1", _current_aa_heavy_upgrade]],
					[Format ["Armored_%1", _current_heavy_upgrade]],
					[Format ["Armored_%1", _current_heavy_upgrade]],
					[Format ["Armored_%1", _current_heavy_upgrade]]
				];

	};
	case (_sv >= 100): {
        _unitTemplates = [
                [Format ["Mechanized_%1", _current_heavy_upgrade]],
                [Format ["AA_Heavy_%1", _current_aa_heavy_upgrade]],
                [Format ["Armored_%1", _current_heavy_upgrade]],
                [Format ["Armored_%1", _current_heavy_upgrade]],
                [Format ["Armored_%1", _current_heavy_upgrade]],
                [Format ["Armored_%1", _current_heavy_upgrade]]
            ];
        _groups_max = _groups_max + 2;
    };
};

_unit_vehicles = [];
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
for '_j' from 0 to (_total_vehicles - 1) do {
    _final pushBack (_unit_vehicles # _j);
};

_contents = [];
{
	_get = missionNamespace getVariable Format ["WF_%1_GROUPS_%2", _side, _x];

	if !(isNil '_get') then {_contents pushBack (_get select floor(random count _get))};
} forEach _final;

_contents