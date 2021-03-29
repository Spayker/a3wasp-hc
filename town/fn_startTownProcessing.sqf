private ["_hc"];
// "towns" use it to get all initiated towns on map
_timeAttacked = 0;
_activeEnemies = 0;
_force = 0;
_lastUp = 0;
_skipTimeSupply = false;
_newSID = -1;
_newSide = civilian;
_town_camps_capture_rate = missionNamespace getVariable "WF_C_CAMPS_CAPTURE_RATE_MAX";

_town_capture_rate = missionNamespace getVariable 'WF_C_TOWNS_CAPTURE_RATE';
_town_supply_time_delay = missionNamespace getVariable "WF_C_ECONOMY_SUPPLY_TIME_INCREASE_DELAY";
_supplyTruckTimeCheckDelay = missionNamespace getVariable "WF_C_ECONOMY_SUPPLY_TRUCK_TIME_CHECK_DELAY";
_town_supply_time = if ((missionNamespace getVariable "WF_C_ECONOMY_SUPPLY_SYSTEM") == 1) then {true} else {false};

_town_occupation_enabled = if ((missionNamespace getVariable "WF_C_TOWNS_OCCUPATION") > 0) then {true} else {false};

_distance = missionNamespace getVariable "WF_C_DEPOT_BUY_DISTANCE";
_direction = missionNamespace getVariable "WF_C_DEPOT_BUY_DIR";

_isTimeToUpdateSuppluys = false;

for "_j" from 0 to ((count towns) - 1) step 1 do {
	_loc = towns # _j;
	["INITIALIZATION",Format ["WFHC_fnc_startTownProcessing : Initialized for [%1].", _loc getVariable "name"]] Call WFCO_FNC_LogContent;
	sleep 0.01;
};

_procesTowns = {
    params ["_isTimeToUpdateSuppluys"];
    _towns = towns - [objNull];
    for "_i" from 0 to ((count _towns) - 1) step 1 do {
        _location = _towns # _i;
        if!(isNil "_location") then {
            _locationSpecialities = _location getVariable "townSpeciality";
            _supplyValue = _location getVariable "supplyValue";
            _maxSupplyValue = _location getVariable "maxSupplyValue";
            _startingSupplyValue = _location getVariable "startingSupplyValue";
            _initialStartingSupplyValue = _location getVariable "initialStartSupplyValue";
            _resFaction = _location getVariable ["resFaction", nil];
            _sideID = _location getVariable ["sideID", WF_C_CIV_ID];
            _side = (_sideID) Call WFCO_FNC_GetSideFromID;
            _objects = (_location nearEntities[WF_C_ALL_MAN_VEHICLE_KINDS_NO_STATIC, 	WF_C_TOWNS_CAPTURE_RANGE]) unitsBelowHeight 10;

            _west = west countSide _objects;
            _east = east countSide _objects;
            _resistance = resistance countSide _objects;

            _activeEnemies = switch (_sideID) do {
                case WF_C_WEST_ID: {_east + _resistance};
                case WF_C_EAST_ID: {_west + _resistance};
                case WF_C_GUER_ID: {_east + _west};
            };

            if (_town_supply_time) then {
                //--- If we're running on 2 sides, skip the time based supply if the defender hold the town.
                _skipTimeSupply = if (_sideID == WF_DEFENDER_ID) then {true} else {false};
            };

            if(_town_supply_time && !_skipTimeSupply) then {
                    if (_isTimeToUpdateSuppluys) then {
                        _increaseOf = 1;
                        if (missionNamespace getVariable Format ["WF_%1_PRESENT",_side]) then {
                            _upgrades = (_side) Call WFCO_FNC_GetSideUpgrades;
                            _increaseOf = 2 * ((missionNamespace getVariable "WF_C_TOWNS_SUPPLY_LEVELS_TIME") # (_upgrades # WF_UP_SUPPLYRATE));
                        };

                        if!(WF_C_MINE in (_locationSpecialities)) then {
                            if(WF_C_WAREHOUSE in (_locationSpecialities)) then {
                                _supplyValue = _supplyValue - _increaseOf;
                                if (_supplyValue <= 0) exitWith {
                                    towns = towns - [_location];
                                    missionNamespace setVariable ["totalTowns", count towns, true];
                                    [_location getVariable "name"] remoteExecCall ["WFCL_FNC_TownRemoved"];
                                    deleteVehicle _location
                                };
                                _location setVariable ["supplyValue", _supplyValue, true]
                            } else {
                                if (_supplyValue < _maxSupplyValue) then {
                                    _supplyValue = _supplyValue + _increaseOf;
                                    if (_supplyValue >= _maxSupplyValue) then {_supplyValue = _maxSupplyValue};
                                    _location setVariable ["supplyValue", _supplyValue, true]
                                }
                            }
                        }
                    }
            };

            if(WF_C_PORT in (_locationSpecialities)) then {

                _shallSpawnSupplyTruck = true;
                if(_sideID == WF_DEFENDER_ID && !(isNil '_resFaction')) then {
                    if(_resFaction == WF_DEFENDER_CDF_FACTION) then {
                        _shallSpawnSupplyTruck = false
                }
            };

                if(_shallSpawnSupplyTruck) then {
                _supplyTruck = _location getVariable ["supplyVehicle", objNull];
                _supplyTruckTimeCheck = _location getVariable ["supplyVehicleTimeCheck", time];
                    if (time >= _supplyTruckTimeCheck) then {
                        if(isNull _supplyTruck) then {
                            _position = _location modelToWorld [(sin _direction * _distance), (cos _direction * _distance), 0];
                            _safePosition = [_position, 30] call WFCO_fnc_getEmptyPosition;

                            _vehicle = [missionNamespace getVariable Format["WF_%1SUPPLY_TRUCK", str _side], _safePosition, _sideID, 0, false, false] Call WFCO_FNC_CreateVehicle;
                            _vehicle setVariable ['isSupplyVehicle', true, true];
                            _location setVariable ["supplyVehicle", _vehicle, true];
                            (format[localize "STR_WF_CHAT_Town_Supply_Truck_Spawned", _location getVariable "name"]) remoteExecCall ["WFCL_FNC_CommandChatMessage", _side];
                            [_side, "SupplyTruckSpawned", _location] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                        };
                        _location setVariable ["supplyVehicleTimeCheck", time + _supplyTruckTimeCheckDelay, true];
                    }
                }
            };

            if(_west > 0 || _east > 0 || _resistance > 0) then {
                _skip = false;
                _captured = false;

                _resistanceDominion = if (_resistance > _east && _resistance > _west) then {true} else {false};
                _westDominion = if (_west > _east && _west > _resistance) then {true} else {false};
                _eastDominion = if (_east > _west && _east > _resistance) then {true} else {false};

                if (_sideID == WF_C_EAST_ID && _eastDominion) then {_force = _east;_skip = true};
                if (_sideID == WF_C_WEST_ID && _westDominion) then {_force = _west;_skip = true};

                if (_sideID == WF_C_GUER_ID && _resistanceDominion) then {
                    if!(isNil '_resFaction') then {
                        if(_resFaction == WF_DEFENDER_CDF_FACTION) then {
                            _force = _resistance;_skip = false
                        } else {
                            _skip = true
                        }
                    }
                };

                if (_resistanceDominion) then {
                    _resistance = _resistance - (selectMax [_east, _west]);
                    _force = _resistance;
                    _east = 0;
                    _west = 0;
                };

                if (_westDominion) then {
                    _west = _west - (selectMax [_east, _resistance]);
                    _force = _west;
                    _east = 0;
                    _resistance = 0;
                };

                if (_eastDominion) then {
                    _east = _east - (selectMax [_west, _resistance]);
                    _force = _east;
                    _west = 0;
                    _resistance = 0;
                };

                if (!_resistanceDominion && !_westDominion && !_eastDominion) then {_west = 0; _east = 0; _resistance = 0};

                _isSpawning = _location getVariable ["wf_spawning", false];
                if(_isSpawning) then { _skip = true };

                if !(_skip) then {
                    _newSID = switch (true) do {case (_west > 0): {WF_C_WEST_ID}; case (_east > 0): {WF_C_EAST_ID}; case (_resistance > 0): {WF_C_GUER_ID}};
                    _newSide = (_newSID) Call WFCO_FNC_GetSideFromID;
                    _rate = _town_capture_rate * (([_location,_newSide] Call WFCO_FNC_GetTotalCampsOnSide) / (_location Call WFCO_FNC_GetTotalCamps)) * _town_camps_capture_rate;
                    if (_rate < 1) then {_rate = 10};

                    if(_sideID == WF_C_GUER_ID) then {
                        if!(isNil '_resFaction') then {
                            if(_resFaction == WF_DEFENDER_GUER_FACTION) then {
                        if (_activeEnemies > 0 && time > _timeAttacked && (missionNamespace getVariable Format ["WF_%1_PRESENT",_side])) then {
                            _timeAttacked = time + 60;
                            [_side, "IsUnderAttack", ["Town", _location]] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                        };
                    };
                    _supplyValue = round(_supplyValue - (_resistance + _east + _west) * _rate);
                    if (_supplyValue < 1) then {_supplyValue = _startingSupplyValue; _captured = true};
                    _location setVariable ["supplyValue",_supplyValue,true];
                        }
                    } else {
                        if (_activeEnemies > 0 && time > _timeAttacked && (missionNamespace getVariable Format ["WF_%1_PRESENT",_side])) then {
                            _timeAttacked = time + 60;
                            [_side, "IsUnderAttack", ["Town", _location]] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                        };

                        _supplyValue = round(_supplyValue - (_resistance + _east + _west) * _rate);
                        if (_supplyValue < 1) then {_supplyValue = _startingSupplyValue; _captured = true};
                        _location setVariable ["supplyValue",_supplyValue,true];
                    }
                };

                if(_captured) then {
                    ["INFORMATION", Format ["WFHC_fnc_startTownProcessing: Town [%1] was captured by [%2] From [%3].", _location, _newSide, _side]] Call WFCO_FNC_LogContent;

                    //--Store town capturing time--
                    _location setVariable ["captureTime",time];
                    [format [":homes: town **%1** was captured by %2%3 from %4%5", _location, _newSide Call WFCO_FNC_GetSideFLAG, _newSide, _side Call WFCO_FNC_GetSideFLAG, _side]] Call WFDC_FNC_LogContent;

                    if(_sideID == WF_C_GUER_ID) then {
                        if!(isNil '_resFaction') then {
                            if(_resFaction == WF_DEFENDER_GUER_FACTION) then {
                                if (missionNamespace getVariable Format ["WF_%1_PRESENT", _side]) then {
                                    [_side, "Lost", _location] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                                }
                            }
                        }
                    } else {
                        if (missionNamespace getVariable Format ["WF_%1_PRESENT",_side]) then {
                            [_side, "Lost", _location] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                        }
                    };

                        if (_newSID == _sideID) then {
                        _location setVariable ["resFaction", WF_DEFENDER_GUER_FACTION, true]
                    } else {
                        if(_newSID == WF_DEFENDER_ID) then {
                            _location setVariable ["resFaction", WF_DEFENDER_GUER_FACTION, true]
                        } else {
                                _location setVariable ["resFaction", nil, true]
                            }
                    };

                    if (missionNamespace getVariable Format ["WF_%1_PRESENT",_newSide]) then {
                        [_newSide, "Captured", _location] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                    };

                    _location setVariable ["sideID",_newSID,true];
                    [_location, _location getVariable "name", _sideID, _newSID] remoteExecCall ["WFCL_FNC_TownCaptured"];
                    [_location, _sideID, _newSID] remoteExecCall ["WFSE_FNC_SetCampsToSide", 2];

                    //--- Clear the town defenses, units first then replace the defenses if needed.
                    [_location, _side, "remove"] spawn WFHC_FNC_OperateTownDefensesUnits;

                    if (WF_C_MINE in _locationSpecialities) then {
                        _locationName = _location getVariable "name";
                        towns = towns - [_location];
                        missionNamespace setVariable ["totalTowns", count towns, true];
                        [_locationName] remoteExecCall ["WFCL_FNC_TownRemoved"];

                        _locationPosition = getPosATL _location;
                        deleteVehicle _location;
                        _vehicle = [missionNamespace getVariable Format["WF_%1SUPPLY_TRUCK", str _newSide], _locationPosition, _newSID, 0, false, false] Call WFCO_FNC_CreateVehicle;
                        _vehicle setVariable ['isSupplyVehicle', true, true];
                        (format[localize "STR_WF_CHAT_Town_Supply_Truck_Spawned", _locationName]) remoteExecCall ["WFCL_FNC_CommandChatMessage", _newSide]
                    };

                    if (WF_C_PORT in _locationSpecialities) then {
                            _position = _location modelToWorld [(sin _direction * _distance), (cos _direction * _distance), 0];
                            _safePosition = [_position, 30] call WFCO_fnc_getEmptyPosition;
                            _vehicle = [missionNamespace getVariable Format["WF_%1SUPPLY_TRUCK", str _newSide], _safePosition, _newSID, 0, false, false] Call WFCO_FNC_CreateVehicle;
                            _vehicle setVariable ['isSupplyVehicle', true, true];
                            _location setVariable ["supplyVehicle", _vehicle, true];
                            _location setVariable ["supplyVehicleTimeCheck", time + _supplyTruckTimeCheckDelay, true];
                            (format[localize "STR_WF_CHAT_Town_Supply_Truck_Spawned", _location getVariable "name"]) remoteExecCall ["WFCL_FNC_CommandChatMessage", _newSide]
                    };

                    // calculating town damage
                    _halfTownRange = (_location getVariable ["range", 500])/2;
                    _initialTownMaxSupplyValue = _location getVariable ["initialMaxSupplyValue", 50];
                    _townRuins = count (nearestObjects [_location, ["Ruins"], _halfTownRange]);
                    _newTownMaxSV = floor (_initialTownMaxSupplyValue - ((_initialTownMaxSupplyValue/100)*_townRuins));

                    if (_newTownMaxSV < _initialTownMaxSupplyValue / 10) then {
                        towns = towns - [_location];
                        missionNamespace setVariable ["totalTowns", count towns, true];
                        [_location getVariable "name", _location getVariable "camps"] remoteExecCall ["WFCL_FNC_TownRemoved"];
                        ["TownCanceled", _location] remoteExecCall ["WFCL_FNC_TaskSystem"];
                        sleep 3;
                        _camps = _location getVariable ["camps", []];
                        { deleteVehicle _x } forEach _camps;

                        deleteVehicle _location
                    } else {
                        _location setVariable ["maxSupplyValue", _newTownMaxSV, true];
                        _currentSupplyValue = _location getVariable ["supplyValue", _newTownMaxSV];
                        if(_currentSupplyValue >= _newTownMaxSV) then {
                            _location setVariable ["supplyValue", _newTownMaxSV, true]
                        }
                    }
                }
            }
        }
    }
};

while {!WF_GameOver} do {
	[_isTimeToUpdateSuppluys] call _procesTowns;
	_isTimeToUpdateSuppluys = false;
	sleep 5;
	if (time >= _lastUp) then {
		_isTimeToUpdateSuppluys = true;
		_lastUp = time + _town_supply_time_delay;
	};
};