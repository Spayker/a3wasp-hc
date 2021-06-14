Private ['_side', '_commanderGroup', '_isAiCommanderRunning'];

while {!WF_GameOver} do {
    sleep 90;
    {
        _side = _x;
        // get team commander
        _commanderGroup = (_side) Call WFCO_FNC_GetCommanderTeam;

        if(isNull _commanderGroup) then {
            // let's run ai commander for current side

            [_side] spawn {
                params ['_side'];
                private ['_sideId', '_factories','_highCommandGroups','_waypoints'];

                _sideId = _side Call WFCO_FNC_GetSideID;

                // get high command groups
                _highCommandGroups = [_side] call WFCO_FNC_getHighCommandGroups;
                if(count _highCommandGroups > 0) then {
                    // time to give orders for HC groups
                    {
                        _group = _x;
                        // get group waypoints
                        _group Call WFCO_fnc_aiWpRemove;

                        // group has no waypoints so we can assign new ones
                        _enemyTowns = [];
                        {
                            if ((_x getVariable 'sideID') != _sideId) then {_enemyTowns pushBackUnique _x}
                        } forEach towns;

                        _sortedTowns = [];
                        if (count _enemyTowns > 0) then {
                            _sortedTowns = [getPosATL (leader _group), _enemyTowns] Call WFCO_FNC_SortByDistance;
                        };

                        [_group, true, [[_sortedTowns # 0, 'SAD', 100, 60, "", []]]] Call WFCO_fnc_aiWpAdd;
                    } forEach _highCommandGroups
                };

                // get available production structures
                _factories = [];
                {
                    _factories = _factories + ([_side, missionNamespace getVariable format ["WF_%1%2TYPE", str _side, _x], (_side Call WFCO_FNC_GetSideStructures)] call WFCO_FNC_GetFactories);
                } forEach WF_C_BASE_PRODUCTION_STRUCTURE_NAMES;

                // define how many groups can be ordered
                _hcAllowedGroupAmount = WF_C_HIGH_COMMAND_MIN_GROUP_AMOUNT + ( (((_side) call WFCO_FNC_GetSideUpgrades) # WF_UP_HC_GROUP_AMOUNT) * 2 );
                _freeHcGroupsAmount = _hcAllowedGroupAmount - (count _highCommandGroups);

                if (_freeHcGroupsAmount > 0 && count _factories > 0) then {
                    // define types of HC groups to be ordered
                    _generalGroupTemplates = missionNamespace getVariable Format["WF_%1AITEAMTEMPLATES", _side];
                    _groupTypes = missionNamespace getVariable Format["WF_%1AITEAMTYPES", _side];
                    _requiredGroupUpgrades = missionNamespace getVariable Format["WF_%1AITEAMUPGRADES", _side];
                    _upgrades = (_side) Call WFCO_FNC_GetSideUpgrades;

                    for "_i" from 1 to _freeHcGroupsAmount do {
                            _factory = _factories # (floor random (count _factories));
                            _structureType = _factory getVariable ['wf_structure_type', ''];

                            // ordering hc group
                            _currentSideUpgradeLevel = 0;
                            switch (_structureType) do {
                                case 'Barracks': {
                                    _currentSideUpgradeLevel = _upgrades # WF_UP_BARRACKS;
                                };
                                case 'Light': {
                                    _currentSideUpgradeLevel = _upgrades # WF_UP_LIGHT;
                                };
                                case 'Heavy': {
                                    _currentSideUpgradeLevel = _upgrades # WF_UP_HEAVY;
                                };
                                case 'Aircraft': {
                                    _currentSideUpgradeLevel = _upgrades # WF_UP_AIR;
                                };
                            };

                            _filteredTemplates = [];
                            {
                                if (_x == _structureType) then {
                                    _templateUpgradeLevel = _requiredGroupUpgrades # _forEachIndex;
                                    if (_currentSideUpgradeLevel >= _templateUpgradeLevel) then {
                                        _selectedGroupTemplate = _generalGroupTemplates # _forEachIndex;
                                        if !(_selectedGroupTemplate in WF_ADV_ARTILLERY) then {
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
                };

                // perform upgrades
                [_side] remoteExecCall ["WFSE_FNC_aiComUpgrade", 2];
            }
        }
    } forEach WF_PRESENTSIDES
}


