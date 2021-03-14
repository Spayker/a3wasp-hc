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

_town_defender_enabled = if ((missionNamespace getVariable "WF_C_TOWNS_DEFENDER") > 0) then {true} else {false};
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
            _maxSupplyValue = _location getVariable "maxSupplyValue";
            _startingSupplyValue = _location getVariable "startingSupplyValue";
            _initialStartingSupplyValue = _location getVariable "initialStartSupplyValue";
            _sideID = _location getVariable ["sideID", WF_C_GUER_ID];
            _side = (_sideID) Call WFCO_FNC_GetSideFromID;
            _objects = (_location nearEntities[WF_C_ALL_MAN_VEHICLE_KINDS_NO_STATIC, 	WF_C_TOWNS_CAPTURE_RANGE]) unitsBelowHeight 10;

            _west = west countSide _objects;
            _east = east countSide _objects;
            _resistance = resistance countSide _objects;
            _civilian = civilian countSide _objects;

            _activeEnemies = switch (_sideID) do {
                case WF_C_WEST_ID: {_east + _resistance + _civilian};
                case WF_C_EAST_ID: {_west + _resistance + _civilian};
                case WF_C_GUER_ID: {_east + _west + _civilian};
                case WF_C_CIV_ID: {_east + _west + _resistance};
            };

            _supplyValue = _location getVariable "supplyValue";

            if (_town_supply_time) then {
                //--- If we're running on 2 sides, skip the time based supply if the defender hold the town.
                _skipTimeSupply = if (_sideID == WF_DEFENDER_ID) then {true} else {false};
            };

            if(_town_supply_time && _sideID != WF_C_UNKNOWN_ID && !_skipTimeSupply) then {
                if (_activeEnemies == 0 && _sideID != WF_C_GUER_ID) then {
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
                }
            };

            if(WF_C_PORT in (_locationSpecialities)) then {
                _supplyTruck = _location getVariable ["supplyVehicle", objNull];
                _supplyTruckTimeCheck = _location getVariable ["supplyVehicleTimeCheck", time];
                if (_side != civilian && _side != resistance) then {
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

            if(_west > 0 || _east > 0 || _resistance > 0 || _civilian > 0) then {
                _skip = false;
                _captured = false;

                _resistanceDominion = if (_resistance > _east && _resistance > _west && _resistance > _civilian) then {true} else {false};
                _civilianDominion = if (_civilian > _east && _civilian > _west && _civilian > _resistance) then {true} else {false};
                _westDominion = if (_west > _east && _west > _resistance && _west > _civilian) then {true} else {false};
                _eastDominion = if (_east > _west && _east > _resistance && _east > _civilian) then {true} else {false};

                if (_sideID == WF_C_GUER_ID && _resistanceDominion) then {_force = _resistance;_skip = true};
                if (_sideID == WF_C_EAST_ID && _eastDominion) then {_force = _east;_skip = true};
                if (_sideID == WF_C_WEST_ID && _westDominion) then {_force = _west;_skip = true};
                if (_sideID == WF_C_CIV_ID && _civilianDominion) then {_force = _civilian;_skip = true};

                if (_civilianDominion) then {
                    _civilian = if (_east > _west) then {_civilian - _east} else {
                        if(_west > _resistance) then {
                            _civilian - _west
                        } else {
                            _civilian - _resistance
                        }
                    };
                    _force = _civilian;
                    _east = 0;
                    _west = 0;
                    _resistance = 0;
                };

                if (_resistanceDominion) then {
                    _resistance = if (_east > _west) then {_resistance - _east} else {
                        if(_west > _civilian) then {
                            _resistance - _west
                        } else {
                            _resistance - _civilian
                        }
                    };
                    _force = _resistance;
                    _east = 0;
                    _west = 0;
                    _civilian = 0;
                };

                if (_westDominion) then {
                    _west = if (_east > _resistance) then {_west - _east} else {
                        if(_resistance > _civilian) then {
                            _west - _resistance
                        } else {
                            _west - _civilian
                        }
                    };
                    _force = _west;
                    _east = 0;
                    _resistance = 0;
                    _civilian = 0;
                };

                if (_eastDominion) then {
                    _east = if (_west > _resistance) then {_east - _west} else {
                        if(_resistance > _civilian) then {
                            _east - _resistance
                        } else {
                            _east - _civilian
                        }
                    };
                    _force = _east;
                    _west = 0;
                    _resistance = 0;
                    _civilian = 0;
                };

                if (!_resistanceDominion && !_westDominion && !_eastDominion && !_civilianDominion) then {_west = 0; _east = 0; _resistance = 0; _civilian = 0};

                _isSpawning = _location getVariable ["wf_spawning", false];
                if(_isSpawning) then { _skip = true };

                if !(_skip) then {
                    _newSID = switch (true) do {case (_west > 0): {WF_C_WEST_ID}; case (_east > 0): {WF_C_EAST_ID}; case (_resistance > 0): {WF_C_GUER_ID}; case (_civilian > 0): {WF_C_CIV_ID};};
                    _newSide = (_newSID) Call WFCO_FNC_GetSideFromID;
                    _rate = _town_capture_rate * (([_location,_newSide] Call WFCO_FNC_GetTotalCampsOnSide) / (_location Call WFCO_FNC_GetTotalCamps)) * _town_camps_capture_rate;
                    if (_rate < 1) then {_rate = 10};

                    if (_sideID != WF_C_UNKNOWN_ID) then {
                        if (_activeEnemies > 0 && time > _timeAttacked && (missionNamespace getVariable Format ["WF_%1_PRESENT",_side])) then {
                            _timeAttacked = time + 60;
                            [_side, "IsUnderAttack", ["Town", _location]] remoteExecCall ["WFSE_FNC_SideMessage", 2]
                        };
                    };

                    _supplyValue = round(_supplyValue - (_resistance + _east + _west + _civilian) * _rate);
                    if (_supplyValue < 1) then {_supplyValue = _startingSupplyValue; _captured = true};
                    _location setVariable ["supplyValue",_supplyValue,true];
                };

                if(_captured) then {
                    ["INFORMATION", Format ["WFHC_fnc_startTownProcessing: Town [%1] was captured by [%2] From [%3].", _location, _newSide, _side]] Call WFCO_FNC_LogContent;

                    //--Store town capturing time--
                    _location setVariable ["captureTime",time];

                    if(_side != civilian && _newSide != civilian) then {
                        [format [":homes: town **%1** was captured by %2%3 from %4%5", _location, _newSide Call WFCO_FNC_GetSideFLAG, _newSide, _side Call WFCO_FNC_GetSideFLAG, _side]] Call WFDC_FNC_LogContent;
                    };

                    _oldSideID = _location getVariable "sideID";

                    if (_sideID != WF_C_UNKNOWN_ID) then {
                        if (missionNamespace getVariable Format ["WF_%1_PRESENT",_side]) then {
                            [_side, "Lost", _location] remoteExecCall ["WFSE_FNC_SideMessage", 2]
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

                    //--- Check if the side is enabled in town and add defenses if needed.
                    _side_enabled = false;
                    if (_newSide == WF_DEFENDER) then {
                        if (_town_defender_enabled) then { _side_enabled = true }
                    } else {
                        if (_town_occupation_enabled) then { _side_enabled = true }
                    };

                    //--If town belonged Civilian, check left groups, if infantry count is low than 9 or TownSV/10 kill them--
                    if(_oldSideID == 3) then {
                        //--Check remaining units in the captured town--
                        _grps = _location getVariable ["wf_town_teams", []];
                        _totalTownUnitsCountLimit = ceil(_maxSupplyValue / 10);
                        if(_totalTownUnitsCountLimit < 9) then { _totalTownUnitsCountLimit = 9 };
                        _totalTownUnitsCount = _totalTownUnitsCountLimit;

                        if(count _grps > 0) then
                        {
                            _totalTownUnitsCount = 0;
                            {
                                {
                                    if(vehicle _x == _x) then {
                                        _totalTownUnitsCount = _totalTownUnitsCount + 1;
                                    };
                                } forEach (units _x);
                            } forEach (_grps);
                        };

                        if(_totalTownUnitsCount <= _totalTownUnitsCountLimit) then {
                            //--Command HC to kill remaining infantry--
                            [_location, 1, false] call WFHC_FNC_RemoveTownAI;
                            [_location, _side, "remove"] spawn WFHC_FNC_OperateTownDefensesUnits
                        } else {
                            //--Remove only man which is in building--
                            [_location, 2, false] call WFHC_FNC_RemoveTownAI;
                            [_location, _side, "remove"] spawn WFHC_FNC_OperateTownDefensesUnits
                        }
                    };

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
                        if (_newSide != resistance && _newSide != civilian) then {
                            _position = _location modelToWorld [(sin _direction * _distance), (cos _direction * _distance), 0];
                            _safePosition = [_position, 30] call WFCO_fnc_getEmptyPosition;
                            _vehicle = [missionNamespace getVariable Format["WF_%1SUPPLY_TRUCK", str _newSide], _safePosition, _newSID, 0, false, false] Call WFCO_FNC_CreateVehicle;
                            _vehicle setVariable ['isSupplyVehicle', true, true];
                            _location setVariable ["supplyVehicle", _vehicle, true];
                            _location setVariable ["supplyVehicleTimeCheck", time + _supplyTruckTimeCheckDelay, true];
                            (format[localize "STR_WF_CHAT_Town_Supply_Truck_Spawned", _location getVariable "name"]) remoteExecCall ["WFCL_FNC_CommandChatMessage", _newSide]
                        }
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