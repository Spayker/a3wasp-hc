Params ['_side', '_logic', '_highCommandGroups'];
Private ['_currentUpgrades', '_currentLevel'];

_isCommandCenterAlive = false;
_commandCenter = objNull;

_heliParatroopInterval = missionNamespace getVariable [Format["WF_%1LastHeliParatroopInterval", str _side], 1000];
_casInterval = missionNamespace getVariable [Format["WF_%1LastCasInterval", str _side], 1000];

if ((time - _heliParatroopInterval > 1000) || (time - _casInterval > 1000)) then {

    //// run Heli Paratroopers
    _factories = [_side, missionNamespace getVariable Format ['WF_%1%2TYPE', str _side, 'CommandCenter'], (_side Call WFCO_FNC_GetSideStructures)] Call WFCO_FNC_GetFactories;
    {
        _factory = _x;
        _structureType = _factory getVariable ['wf_structure_type', ''];
        if (_structureType == 'CommandCenter') exitWith {
            _isCommandCenterAlive = true;
            _commandCenter = _factory;
        }
    } forEach _factories;

    if (_isCommandCenterAlive) then {

        _currentUpgrades = (_side) Call WFCO_FNC_GetSideUpgrades;

        _enemyTowns = [];
        {
            _townSideId = _x getVariable 'sideID';
            _friendlySides = _logic getVariable ["wf_friendlySides", []];

            if (count _friendlySides > 0) then {
                _townSide = _townSideId Call WFCO_FNC_GetSideFromID;
                if !(_townSide in _friendlySides) then { _enemyTowns pushBackUnique _x }
            } else {
                if (_townSideId != _sideId) then { _enemyTowns pushBackUnique _x }
            }
        } forEach towns;

        _sortedTowns = [];
        if (count _enemyTowns > 0) then { _sortedTowns = [getPosATL _commandCenter, _enemyTowns] Call WFCO_FNC_SortByDistance };

        if (time - _heliParatroopInterval > 1000) then {
            _currentLevel = _currentUpgrades # WF_UP_PARATROOPERS;

            if (_currentLevel > 0) then {
                _hcAllowedGroupAmount = WF_C_HIGH_COMMAND_MIN_GROUP_AMOUNT + ( (((_side) call WFCO_FNC_GetSideUpgrades) # WF_UP_HC_GROUP_AMOUNT) * 2 );
                _freeHcGroupsAmount = _hcAllowedGroupAmount - (count _highCommandGroups);

                if (_freeHcGroupsAmount > 0) then {
                    _destination = [getPosATL (_sortedTowns # 0), 300] call WFCO_FNC_GetSafePlace;
                    [_side, _destination, grpNull, 10, true] spawn WFCO_FNC_HeliParatroopers;
                    missionNamespace setVariable [Format["WF_%1LastHeliParatroopInterval", str _side], time]
                }
            }
        };

        if (time - _casInterval > 1000) then {
            _destination = getPosATL (_sortedTowns # 0);
            [_side, _destination] spawn WFCO_FNC_casRequest;
            missionNamespace setVariable [Format["WF_%1LastCasInterval", str _side], time]
        }
    }
}


//// run CAS



