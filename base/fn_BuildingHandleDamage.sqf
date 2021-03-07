params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];
private ["_master", "_health"];

_damage = _damage * 3000;
_damage = _damage / (_unit getVariable ["wf_reducer", 1]);

_master = _unit getVariable ["wf_structure_master", _unit];

if(WF_C_BASE_ALLOW_TEAM_DAMMAGE <= 0 && ((side _source) == (_master getVariable "wf_side"))) exitWith {0};

_health = _master getVariable ["wf_site_health", 0];

if(_damage < _health) then {
    _health = _health - _damage
} else {
    _health = 0
};

_master setVariable ["wf_site_health", _health, true];
_master setVariable ["wf_instigator", _instigator, true];

if(_health <= 0 && _master getVariable ["wf_site_alive", true]) then {
    _master setVariable ["wf_site_alive", false, true];

    _master removeAllEventHandlers "Hit";
    _master removeAllEventHandlers "HandleDamage";


    [_master] call WFHC_FNC_BuildingKilled;

    _side = _master getVariable "wf_side";
    if (_side == resistance) then {
        [_side, getPosAtl _master] spawn WFCO_fnc_cleanResBaseArea
    }
};

_damage