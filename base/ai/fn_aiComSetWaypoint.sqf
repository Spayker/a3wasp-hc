Params ['_group', '_logic'];
Private ['_enemyTowns', '_townSideId', '_friendlySides', '_townSide', '_sortedTowns', '_isInfantry', '_waypoints'];

// get group waypoints
_group Call WFCO_fnc_aiWpRemove;

// group has no waypoints so we can assign new ones
_enemyTowns = [];
{
    _townSideId = _x getVariable 'sideID';
    _friendlySides = _logic getVariable ["wf_friendlySides", []];

    if (count _friendlySides > 0) then {
        _townSide = _townSideId Call WFCO_FNC_GetSideFromID;
        if !(_townSide in _friendlySides) then {
            _enemyTowns pushBackUnique _x
        }
    } else {
        if (_townSideId != _sideId) then {
            _enemyTowns pushBackUnique _x
        }
    }
} forEach towns;
diag_log format ['fn_aiCommander.sqf: _enemyTowns - %1', _enemyTowns];

_sortedTowns = [];
if (count _enemyTowns > 0) then {
    _sortedTowns = [getPosATL (leader _group), _enemyTowns] Call WFCO_FNC_SortByDistance;
};
diag_log format ['fn_aiCommander.sqf: _sortedTowns - %1', _sortedTowns];

[_group, true, [[_sortedTowns # 0, 'SAD', 100, 60, "", []]]] Call WFCO_fnc_aiWpAdd;

_isInfantry = _group getVariable ["isHighCommandInfantry", false];
if(_isInfantry) then {
    _waypoints = waypoints _group;
    if (count _waypoints > 0) then {
        _group setBehaviour "SAFE";
        _group setCombatMode  "RED";

        { _x setWaypointBehaviour 'AWARE' } forEach _waypoints
    }
}