params ["_allDefences", "_pos"];
private ["_action","_defense","_side","_spawn","_town","_units","_sideID","_hc"];

_side = civilian;
_team = createGroup [_side, true];
missionNamespace setVariable [format ["WF_%1_DefenseTeam", _side], _team];

//--- Man the defenses.
{
    _defense = _x;
    if !(isNil '_defense') then {
        if !(alive gunner _defense) then { //--- Make sure that the defense gunner is null or dead.
            _position = getPosATL _x;
            _gunnerType = missionNamespace getVariable format ["WF_%1SOLDIER", _side];
            [_side, _team, [_defense]] call WFHC_FNC_DelegateAIStaticDefence
        }
    }
} forEach (_allDefences)