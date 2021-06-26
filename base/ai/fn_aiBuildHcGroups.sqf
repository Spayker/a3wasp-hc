Params ['_side', '_highCommandGroups'];
Private ['_generalGroupTemplates', '_groupTypes', '_requiredGroupUpgrades', '_upgrades', '_factory', '_i', '_structureType', '_currentSideUpgradeLevel', '_filteredTemplates', '_templateUpgradeLevel', '_currentSideUpgradeLevel', '_selectedGroupTemplate', '_shallAdd', '_spawnPosition', '_position', '_factoryPosition', '_direction', '_commonTime', '_firstClassName', '_firstUnitConfig', '_hcAllowedGroupAmount', '_freeHcGroupsAmount', '_factories'];

// get available production structures
_factories = [];
{
    _factories = _factories + ([_side, missionNamespace getVariable format ["WF_%1%2TYPE", str _side, _x], (_side Call WFCO_FNC_GetSideStructures)] call WFCO_FNC_GetFactories);
} forEach WF_C_BASE_PRODUCTION_STRUCTURE_NAMES;

_hcAllowedGroupAmount = WF_C_HIGH_COMMAND_MIN_GROUP_AMOUNT + ( (((_side) call WFCO_FNC_GetSideUpgrades) # WF_UP_HC_GROUP_AMOUNT) * 2 );
_freeHcGroupsAmount = _hcAllowedGroupAmount - (count _highCommandGroups);

diag_log format ['fn_aiCommander.sqf: _freeHcGroupsAmount - %1', _freeHcGroupsAmount];

if (_freeHcGroupsAmount > 0 && count _factories > 0) then {
    // define types of HC groups to be ordered
    _generalGroupTemplates = missionNamespace getVariable Format["WF_%1AITEAMTEMPLATES", _side];
    _groupTypes = missionNamespace getVariable Format["WF_%1AITEAMTYPES", _side];
    _requiredGroupUpgrades = missionNamespace getVariable Format["WF_%1AITEAMUPGRADES", _side];
    _upgrades = (_side) Call WFCO_FNC_GetSideUpgrades;

    for "_i" from 1 to _freeHcGroupsAmount do {
        _factory = _factories # (floor random (count _factories));
        _structureType = _factory getVariable ['wf_structure_type', ''];
        diag_log format ['fn_aiCommander.sqf: _structureType - %1', _structureType];

        // ordering hc group
        _currentSideUpgradeLevel = 0;
        switch (_structureType) do {
            case 'Barracks': {  _currentSideUpgradeLevel = _upgrades # WF_UP_BARRACKS };
            case 'Light': { _currentSideUpgradeLevel = _upgrades # WF_UP_LIGHT };
            case 'Heavy': { _currentSideUpgradeLevel = _upgrades # WF_UP_HEAVY };
            case 'Aircraft': { _currentSideUpgradeLevel = _upgrades # WF_UP_AIR };
        };

        _filteredTemplates = [];
        {
            if (_x == _structureType) then {
                _templateUpgradeLevel = _requiredGroupUpgrades # _forEachIndex;
                if (_currentSideUpgradeLevel >= _templateUpgradeLevel) then {
                    _selectedGroupTemplate = _generalGroupTemplates # _forEachIndex;
                    _shallAdd = true;
                    if ((_selectedGroupTemplate # 0) in WF_ADV_ARTILLERY) then { _shallAdd = false };

                    if((_selectedGroupTemplate # 0) in (missionNamespace getVariable [format["WF_%1REPAIRTRUCKS", _side], []])) then {
                        _shallAdd = false
                    };

                    if(_shallAdd) then {
                        _filteredTemplates pushBack (_selectedGroupTemplate)
                    }
                }
            }
        } forEach _groupTypes;

        if (count _filteredTemplates > 0) then {
            _selectedGroupTemplate = selectRandom _filteredTemplates;
            _spawnPosition = _factory getVariable 'respawnPoint';
            _position = [_spawnPosition, 30] call WFCO_fnc_getEmptyPosition;
            _factoryPosition = getPos _factory;
            _direction = -((((_position # 1) - (_factoryPosition # 1)) atan2 ((_position # 0) - (_factoryPosition # 0))) - 90);
            [_side, _selectedGroupTemplate, _position, _direction] call WFHC_fnc_CreateHighCommandGroup;

            _commonTime = 0;
            {
                _firstClassName = _selectedGroupTemplate # 0;
                _firstUnitConfig = missionNamespace getVariable _firstClassName;
                _commonTime = _commonTime + (_firstUnitConfig # QUERYUNITTIME)
            } foreach _selectedGroupTemplate;
            sleep _commonTime
        }
    }
}