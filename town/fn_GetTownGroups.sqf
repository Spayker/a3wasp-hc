/*
	Return a list of groups to spawn in a town.
	 Parameters:
		- Town Entity.
		- Side.
*/
params ["_town", "_side"];
private ["_groups_max","_current_infantry_upgrade","_town_airactive","_units","_side","_sv","_town",
"_unitTemplateCount","_randomSelectedTemplate","_unitTemplates","_total_infantry","_total_infantry","_contents",
"_final","_startingSupplyValue","_campsCount"];

_sv = _town getVariable "supplyValue";
_town_airactive = _town getVariable "wf_active_air";
_startingSupplyValue = _town getVariable "startingSupplyValue";
_townDefendersSpeciality = _town getVariable ["townDefendersSpeciality", []];
_unitTemplates = [];
_units = [];

_groups_max = 2;
_campsCount = count (_town getVariable "camps");
if(_campsCount > 0) then { _groups_max = _campsCount };
if(_groups_max > 0 && _groups_max <= 2) then { _groups_max = 3 };

_current_infantry_upgrade = 0;
if (_side != civilian) then {
    _upgrades = (_side) Call WFCO_FNC_GetSideUpgrades;
    _current_infantry_upgrade = _upgrades select WF_UP_BARRACKS;
    _unitsCoef = missionNamespace getVariable "WF_C_TOWNS_UNITS_COEF";
    if (_unitsCoef == 0) then {
        _groups_max = 0;
    } else {
        _groups_max = round(_groups_max * _unitsCoef);
        if(_sv == _startingSupplyValue) then { _groups_max = 1; };
    };
} else {
    _current_infantry_upgrade = floor random 4;
    _sv = _town getVariable "maxSupplyValue";
    _groups_max = round(_groups_max * (missionNamespace getVariable "WF_C_TOWNS_UNITS_DEFENDER_COEF"));
};

if (count _townDefendersSpeciality > 0) then {
    _infantrySpeciality = _townDefendersSpeciality # 0;
    _infantryGroupAmount = _infantrySpeciality # 0;
    _infantryQuality = _infantrySpeciality # 1;
    _groups_max = _infantryGroupAmount;

    switch (_infantryQuality) do {
        case 'light':{ _sv = 20 };
        case 'medium':{ _sv = 80 };
        case 'heavy':{ _sv = 120 };
    }
};



switch (true) do {
	case (_sv <= 10): {
		_unitTemplates = [
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]]
				];
	};
	case (_sv > 10 && _sv < 20): {
		_unitTemplates = [
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]]
				 ];
	};
	case (_sv >= 20 && _sv < 40): {
		_unitTemplates = [
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]]
				];

	};
	case (_sv >= 40 && _sv < 60): {
		_unitTemplates = [
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]],
					[format ["Team_MG_%1", _current_infantry_upgrade]]
				];

	};
	case (_sv >= 60 && _sv < 80): {
		_unitTemplates = [
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Team_MG_%1", _current_infantry_upgrade]],
					["Team_AA"],
					[format ["Team_AT_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]],
					[format ["Team_Sniper_%1", _current_infantry_upgrade]]
				];

	};
	case (_sv >= 80 && _sv < 100): {
		_unitTemplates = [
					[format ["Team_MG_%1", _current_infantry_upgrade]],
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_AT_%1", _current_infantry_upgrade]],
					[if(_current_infantry_upgrade == 3)then{"Squad_Advanced"}else{format ["Squad_%1", _current_infantry_upgrade]}]
				];

	};
	case (_sv >= 100): {
		_unitTemplates = [
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Squad_%1", _current_infantry_upgrade]],
					[format ["Team_MG_%1", _current_infantry_upgrade]],
					[format ["Team_%1", _current_infantry_upgrade]],
					[format ["Team_%1", _current_infantry_upgrade]],
					["Team_AA"],
					[format ["Team_AT_%1", _current_infantry_upgrade]],
					[if(_current_infantry_upgrade == 3)then{"Squad_Advanced"}else{format ["Squad_%1", _current_infantry_upgrade]}],
					[format ["Team_Sniper_%1", _current_infantry_upgrade]]
				];
	};
};

_unit_infantry = [];
_k = 0;
for '_j' from 0 to (_groups_max - 1) do {
    _units pushBack ((_unitTemplates # _k));
    if(_k <= (count _unitTemplates) - 1) then {
        _k = _k + 1;
    } else {
        _k = 0;
    };
};

{
	if (!isNil {missionNamespace getVariable format ["WF_%1_GROUPS_%2", _side, _x # 0]}) then {
        _unit_infantry pushBack (_x # 0)
	}
} forEach _units;

_total_infantry = count _unit_infantry;
if ((_total_infantry) == 0) exitWith {[]};
if (_total_infantry > 1) then {_unit_infantry = (_unit_infantry) Call WFCO_FNC_ArrayShuffle};

_final = [];

for '_j' from 0 to (_total_infantry - 1) do {
    _final pushBack (_unit_infantry # _j);
};

_contents = [];
{
	_get = missionNamespace getVariable format ["WF_%1_GROUPS_%2", _side, _x];

	if !(isNil '_get') then {_contents pushBack (_get select floor(random count _get))};
} forEach _final;

_contents