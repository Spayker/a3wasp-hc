params ['_resBasePositions'];
private ["_posX", "_posY", "_multiplyMatrixFunc"];

["INITIALIZATION", "fn_CreateBaseComposition.sqf: create res bases process has been started."] Call WFCO_FNC_LogContent;
_azi = 0;

missionNamespace setVariable ['WF_NEURODEF_RESISTANCE_BR', [
    ["CUP_I_ZU23_NAPA",[-3.94189,0.834961,-0.075161],271.306],
    ["Land_StoneWall_01_s_d_F",[-6.88037,0.893066,0],268.267],
    ["Gue_WarfareBBarracks",[10.6921,0.741211,0],178.933],
    ["CUP_I_DSHKM_NAPA",[23.6787,-1.04395,-0.0750008],89.7327],
    ["Land_fort_bagfence_round",[24.5161,2.25732,0],11.2262],
    ["Land_fort_bagfence_round",[24.8291,-3.47168,0],161.226]
]];

missionNamespace setVariable ['WF_NEURODEF_RESISTANCE_LF', [
    ["CUP_I_ZU23_NAPA",[-3.94189,0.834961,-0.075161],271.306],
    ["Land_StoneWall_01_s_d_F",[-6.88037,0.893066,0],268.267],
    ["Gue_WarfareBLightFactory",[10.6921,0.741211,0],178.933],
    ["CUP_I_DSHKM_NAPA",[23.6787,-1.04395,-0.0750008],89.7327],
    ["Land_fort_bagfence_round",[24.5161,2.25732,0],11.2262],
    ["Land_fort_bagfence_round",[24.8291,-3.47168,0],161.226]
]];

missionNamespace setVariable ['WF_NEURODEF_RESISTANCE_HF', [
    ["CUP_I_ZU23_NAPA",[-3.94189,0.834961,-0.075161],271.306],
    ["Land_StoneWall_01_s_d_F",[-6.88037,0.893066,0],268.267],
    ["Gue_WarfareBHeavyFactory",[10.6921,0.741211,0],178.933],
    ["CUP_I_DSHKM_NAPA",[23.6787,-1.04395,-0.0750008],89.7327],
    ["Land_fort_bagfence_round",[24.5161,2.25732,0],11.2262],
    ["Land_fort_bagfence_round",[24.8291,-3.47168,0],161.226]
]];

missionNamespace setVariable ['WF_NEURODEF_RESISTANCE_AF', [
    ["CUP_I_ZU23_NAPA",[-3.94189,0.834961,-0.075161],271.306],
    ["Land_StoneWall_01_s_d_F",[-6.88037,0.893066,0],268.267],
    ["GUE_WarfareBAircraftFactory",[10.6921,0.741211,0],178.933],
    ["CUP_I_DSHKM_NAPA",[23.6787,-1.04395,-0.0750008],89.7327],
    ["Land_fort_bagfence_round",[24.5161,2.25732,0],11.2262],
    ["Land_fort_bagfence_round",[24.8291,-3.47168,0],161.226]
]];

_resBasePositions = [_azi, _resBasePositions] call {
    _azi = _this # 0;
    _resBasePositions = _this # 1;
    _positionsToBuildBR = [];

    _multiplyMatrixFunc = {
    	private ["_array1", "_array2", "_result"];
    	_array1 = _this # 0;
    	_array2 = _this # 1;
    	_result =
    	[
    		(((_array1 # 0) # 0) * (_array2 # 0)) + (((_array1 # 0) # 1) * (_array2 # 1)),
    		(((_array1 # 1) # 0) * (_array2 # 0)) + (((_array1 # 1) # 1) * (_array2 # 1))
    	];
    	_result
    };

    if (count _resBasePositions > 0) then {
        while{count _positionsToBuildBR != 2} do {
            _selectedRandomBRBaseLocation = selectRandom _resBasePositions;
            if !(isNil "_selectedRandomBRBaseLocation") then {

                _town = [_selectedRandomBRBaseLocation] Call WFCO_FNC_GetClosestLocation;
                _townside =  (_town getVariable "sideID") Call WFCO_FNC_GetSideFromID;

                if!(isNil '_townside') then {
                if!(_selectedRandomBRBaseLocation in _positionsToBuildBR) then {
                    if(count _positionsToBuildBR == 0) then {
                            if(_townside == WF_DEFENDER) then {
                                _positionsToBuildBR pushBack (_selectedRandomBRBaseLocation);
                                _resBasePositions = _resBasePositions - [_selectedRandomBRBaseLocation];
                        }
                    } else {
                        for [{_i = 0},{_i < count _positionsToBuildBR},{_i = _i + 1}] do {
                            _canPush = true;
                                if((_positionsToBuildBR # _i) distance _selectedRandomBRBaseLocation < 3000) then { _canPush = false };

                            if(_canPush == true) then {
                                if(_townside != WF_DEFENDER) then { _canPush = false }
                            };

                            if(_i == (count _positionsToBuildBR) - 1 && _canPush) then {
                                    _positionsToBuildBR pushBack (_selectedRandomBRBaseLocation);
                                    _resBasePositions = _resBasePositions - [_selectedRandomBRBaseLocation];
                            }
                        }
                    }
                }
            }
            }
        };

        _objs   = missionNamespace getVariable "WF_NEURODEF_RESISTANCE_BR";
        for [{_i = 0}, {_i < count _positionsToBuildBR}, {_i = _i + 1}] do {
            _pos = _positionsToBuildBR # _i;
            _posX = _pos # 0;
            _posY = _pos # 1;
            _defences = [];
            for "_j" from 0 to ((count _objs) - 1) do {
            	private ["_obj", "_type", "_relPos", "_azimuth", "_newObj"];
            	_obj = _objs # _j;
            	_type = _obj # 0;
            	_relPos = _obj # 1;
            	_azimuth = _obj # 2;

            	private ["_rotMatrix", "_newRelPos", "_newPos", "_z"];
            	_rotMatrix =[[cos _azi, sin _azi],[-(sin _azi), cos _azi]];
            	_newRelPos = [_rotMatrix, _relPos] call _multiplyMatrixFunc;
            	if ((count _relPos) > 2) then {_z = _relPos # 2;} else {_z = 0;};
            	_newPos = [_posX + (_newRelPos # 0), _posY + (_newRelPos # 1), _z];

                if (_type in WF_C_STATIC_DEFENCE_FOR_COMPOSITIONS) then {
                    _newObj = _type createVehicle _newPos;
                    _newObj enableSimulation false;
                    _newObj enableSimulation true;
                    _newObj addMPEventHandler ['MPKilled', {
                        params ["_unit", "_killer", "_instigator", "_useEffects"];
                        [_unit,_killer] call WFCO_FNC_OnUnitKilled
                    }];
                    _defences pushBack _newObj
                } else {
                    _newObj = _type createVehicle _newPos
                };

            	if(_type in WF_C_GARBAGE_OBJECTS) then { _newObj enableSimulation false };

            	if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 0)) then {
            	    [_newObj, resistance, (missionNamespace getVariable Format["WF_%1STRUCTURES",str resistance]) # 0, 0] spawn WFHC_FNC_processBrBase
            	};

            	_newObj setDir (_azi + _azimuth);

                if (WF_Debug) then {
                    if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 0)) then {
                        _marker = format ['ResBR%1', time];
                        createMarker [_marker,getPosATL _newObj];
                        _marker setMarkerTextLocal format ['ResBR%1', time];
                        _marker setMarkerType "mil_box";
                        _marker setMarkerColor 'ColorGreen'
                    }
                }
            };
            [_defences, _pos] call WFHC_FNC_ManningOfResBaseDefense
        }
    };
    _resBasePositions
};

_resBasePositions = [_azi, _resBasePositions] call {
    _azi = _this # 0;
    _resBasePositions = _this # 1;
    _positionsToBuildLF = [];

    _multiplyMatrixFunc = {
    	private ["_array1", "_array2", "_result"];
    	_array1 = _this # 0;
    	_array2 = _this # 1;
    	_result =
    	[
    		(((_array1 # 0) # 0) * (_array2 # 0)) + (((_array1 # 0) # 1) * (_array2 # 1)),
    		(((_array1 # 1) # 0) * (_array2 # 0)) + (((_array1 # 1) # 1) * (_array2 # 1))
    	];
    	_result
    };

    if (count _resBasePositions > 0) then {
        while{count _positionsToBuildLF != 2} do {
            _selectedRandomLFBaseLocation = selectRandom _resBasePositions;
            if !(isNil "_selectedRandomLFBaseLocation") then {
                if!(_selectedRandomLFBaseLocation in _positionsToBuildLF) then {

                            _town = [_selectedRandomLFBaseLocation] Call WFCO_FNC_GetClosestLocation;
                            _townside =  (_town getVariable "sideID") Call WFCO_FNC_GetSideFromID;

                    if!(isNil '_townside') then {
                        if(count _positionsToBuildLF == 0) then {
                            if(_townside == WF_DEFENDER) then {
                                _positionsToBuildLF pushBack (_selectedRandomLFBaseLocation);
                                _resBasePositions = _resBasePositions - [_selectedRandomLFBaseLocation];
                            }
                    } else {
                        for [{_i = 0},{_i < count _positionsToBuildLF},{_i = _i + 1}] do {
                            _canPush = true;
                                if((_positionsToBuildLF # _i) distance _selectedRandomLFBaseLocation < 3000) then { _canPush = false };

                            if(_canPush == true) then {
                                if(_townside != WF_DEFENDER) then { _canPush = false }
                            };

                            if(_i == (count _positionsToBuildLF) - 1 && _canPush) then {
                                    _positionsToBuildLF pushBack (_selectedRandomLFBaseLocation);
                                    _resBasePositions = _resBasePositions - [_selectedRandomLFBaseLocation];
                            }
                        }
                    }
                }
            }
            }
        };

        _objs   = missionNamespace getVariable "WF_NEURODEF_RESISTANCE_LF";
        for [{_i = 0}, {_i < count _positionsToBuildLF}, {_i = _i + 1}] do {
            _pos = _positionsToBuildLF # _i;
            _posX = _pos # 0;
            _posY = _pos # 1;
            _defences = [];
            for "_j" from 0 to ((count _objs) - 1) do {
            	private ["_obj", "_type", "_relPos", "_azimuth", "_newObj"];
            	_obj = _objs # _j;
            	_type = _obj # 0;
            	_relPos = _obj # 1;
            	_azimuth = _obj # 2;

            	private ["_rotMatrix", "_newRelPos", "_newPos", "_z"];
            	_rotMatrix =[[cos _azi, sin _azi],[-(sin _azi), cos _azi]];
            	_newRelPos = [_rotMatrix, _relPos] call _multiplyMatrixFunc;
            	if ((count _relPos) > 2) then {_z = _relPos # 2;} else {_z = 0;};
            	_newPos = [_posX + (_newRelPos # 0), _posY + (_newRelPos # 1), _z];

                if (_type in WF_C_STATIC_DEFENCE_FOR_COMPOSITIONS) then {
                    _newObj = _type createVehicle _newPos;
                    _newObj enableSimulation false;
                    _newObj enableSimulation true;
                    _newObj addMPEventHandler ['MPKilled', {
                        params ["_unit", "_killer", "_instigator", "_useEffects"];
                        [_unit,_killer] call WFCO_FNC_OnUnitKilled
                    }];
                    _defences pushBack _newObj
                } else {
                    _newObj = _type createVehicle _newPos
                };

            	if(_type in WF_C_GARBAGE_OBJECTS) then { _newObj enableSimulation false };

            	if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 1)) then {
            	    [_newObj, resistance, (missionNamespace getVariable Format["WF_%1STRUCTURES",str resistance]) # 1, 1] spawn WFHC_FNC_processLfBase
            	};

            	_newObj setDir (_azi + _azimuth);

                if (WF_Debug) then {
                    if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 1)) then {
                        _marker = format ['ResLF%1', time];
                        createMarker [_marker,getPosATL _newObj];
                        _marker setMarkerTextLocal format ['ResLF%1', time];
                        _marker setMarkerType "mil_box";
                        _marker setMarkerColor 'ColorGreen'
                    }
                }
            };
            [_defences, _pos] call WFHC_FNC_ManningOfResBaseDefense
        }
    };
    _resBasePositions
};

_resBasePositions = [_azi, _resBasePositions] call {
    _azi = _this # 0;
    _resBasePositions = _this # 1;
    _positionsToBuildHF = [];

    _multiplyMatrixFunc = {
        private ["_array1", "_array2", "_result"];
        _array1 = _this # 0;
        _array2 = _this # 1;
        _result =
        [
            (((_array1 # 0) # 0) * (_array2 # 0)) + (((_array1 # 0) # 1) * (_array2 # 1)),
            (((_array1 # 1) # 0) * (_array2 # 0)) + (((_array1 # 1) # 1) * (_array2 # 1))
        ];
        _result
    };

    if (count _resBasePositions > 0) then {
        while{count _positionsToBuildHF != 2} do {
            _selectedRandomHFBaseLocation = selectRandom _resBasePositions;
            if !(isNil "_selectedRandomHFBaseLocation") then {
                if!(_selectedRandomHFBaseLocation in _positionsToBuildHF)then{

                            _town = [_selectedRandomHFBaseLocation] Call WFCO_FNC_GetClosestLocation;
                            _townside =  (_town getVariable "sideID") Call WFCO_FNC_GetSideFromID;

                    if!(isNil '_townside') then {
                        if(count _positionsToBuildHF == 0) then {
                            if(_townside == WF_DEFENDER) then {
                                _positionsToBuildHF pushBack (_selectedRandomHFBaseLocation);
                                _resBasePositions = _resBasePositions - [_selectedRandomHFBaseLocation];
                            }
                    }else{
                        for [{_i = 0},{_i < count _positionsToBuildHF},{_i = _i + 1}] do {
                            _canPush = true;
                                if((_positionsToBuildHF # _i) distance _selectedRandomHFBaseLocation < 3000) then { _canPush = false };

                            if(_canPush == true) then {
                                if(_townside != WF_DEFENDER) then { _canPush = false }
                            };

                            if(_i == (count _positionsToBuildHF) - 1 && _canPush) then {
                                    _positionsToBuildHF pushBack (_selectedRandomHFBaseLocation);
                                    _resBasePositions = _resBasePositions - [_selectedRandomHFBaseLocation];
                            }
                        }
                    }
                }
            }
            }
        };

        _objs   = missionNamespace getVariable "WF_NEURODEF_RESISTANCE_HF";
        for [{_i = 0},{_i < count _positionsToBuildHF},{_i = _i + 1}] do {
            _pos = _positionsToBuildHF # _i;
            _posX = _pos # 0;
            _posY = _pos # 1;
            _defences = [];
            for "_j" from 0 to ((count _objs) - 1) do {
                private ["_obj", "_type", "_relPos", "_azimuth", "_newObj"];
                _obj = _objs # _j;
                _type = _obj # 0;
                _relPos = _obj # 1;
                _azimuth = _obj # 2;

                private ["_rotMatrix", "_newRelPos", "_newPos", "_z"];
                _rotMatrix =[[cos _azi, sin _azi],[-(sin _azi), cos _azi]];
                _newRelPos = [_rotMatrix, _relPos] call _multiplyMatrixFunc;
                if ((count _relPos) > 2) then {_z = _relPos # 2;} else {_z = 0;};
                _newPos = [_posX + (_newRelPos # 0), _posY + (_newRelPos # 1), _z];
                if(_type in WF_C_STATIC_DEFENCE_FOR_COMPOSITIONS)then{
                    _newObj = _type createVehicle _newPos;
                    _newObj enableSimulation false;
                    _newObj enableSimulation true;
                    _newObj addMPEventHandler ['MPKilled', {
                        params ["_unit", "_killer", "_instigator", "_useEffects"];
                        [_unit,_killer] call WFCO_FNC_OnUnitKilled
                    }];
                    _defences pushBack _newObj
                }else{
                    _newObj = _type createVehicle _newPos
                };

                if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 2)) then {
                    [_newObj, resistance, (missionNamespace getVariable Format["WF_%1STRUCTURES",str resistance]) # 2, 2] spawn WFHC_FNC_processHfBase
                };

                _newObj setDir (_azi + _azimuth);

                if (WF_Debug) then {
                    if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 2)) then {
                        _marker = format ['ResHF%1', time];
                        createMarker [_marker,getPosATL _newObj];
                        _marker setMarkerTextLocal format ['ResHF%1', time];
                        _marker setMarkerType "mil_box";
                        _marker setMarkerColor 'ColorGreen'
                    }
                }
            };
            [_defences, _pos] call WFHC_FNC_ManningOfResBaseDefense
        }
    };
    _resBasePositions
};

_resBasePositions = [_azi, _resBasePositions] call {
    _azi = _this # 0;
    _resBasePositions = _this # 1;
    _positionsToBuildAF = [];

    _multiplyMatrixFunc = {
        private ["_array1", "_array2", "_result"];
        _array1 = _this # 0;
        _array2 = _this # 1;
        _result =
        [
            (((_array1 # 0) # 0) * (_array2 # 0)) + (((_array1 # 0) # 1) * (_array2 # 1)),
            (((_array1 # 1) # 0) * (_array2 # 0)) + (((_array1 # 1) # 1) * (_array2 # 1))
        ];
        _result
    };

    if (count _resBasePositions > 0) then {
        while{count _positionsToBuildAF != 2} do {
            _selectedRandomAFBaseLocation = selectRandom _resBasePositions;
            if !(isNil "_selectedRandomAFBaseLocation") then {
                if!(_selectedRandomAFBaseLocation in _positionsToBuildAF)then{

                            _town = [_selectedRandomAFBaseLocation] Call WFCO_FNC_GetClosestLocation;
                            _townside =  (_town getVariable "sideID") Call WFCO_FNC_GetSideFromID;

                    if!(isNil '_townside') then {
                        if(count _positionsToBuildAF == 0)then{
                            if(_townside == WF_DEFENDER) then {
                                _positionsToBuildAF pushBack (_selectedRandomAFBaseLocation);
                                _resBasePositions = _resBasePositions - [_selectedRandomAFBaseLocation];
                            }
                    }else{
                        for [{_i = 0},{_i < count _positionsToBuildAF},{_i = _i + 1}] do {
                            _canPush = true;
                                if((_positionsToBuildAF # _i) distance _selectedRandomAFBaseLocation < 3000) then { _canPush = false };

                            if(_canPush == true) then {
                                if(_townside != WF_DEFENDER) then { _canPush = false }
                            };

                            if(_i == (count _positionsToBuildAF) - 1 && _canPush)then{
                                    _positionsToBuildAF pushBack (_selectedRandomAFBaseLocation);
                                    _resBasePositions = _resBasePositions - [_selectedRandomAFBaseLocation];
                            }
                        }
                    }
                }
            }
            }
        };

        _objs   = missionNamespace getVariable "WF_NEURODEF_RESISTANCE_AF";
        for [{_i = 0},{_i < count _positionsToBuildAF},{_i = _i + 1}] do {
            _pos = _positionsToBuildAF # _i;
            _posX = _pos # 0;
            _posY = _pos # 1;
            _defences = [];
            for "_j" from 0 to ((count _objs) - 1) do {
                private ["_obj", "_type", "_relPos", "_azimuth", "_newObj"];
                _obj = _objs # _j;
                _type = _obj # 0;
                _relPos = _obj # 1;
                _azimuth = _obj # 2;

                private ["_rotMatrix", "_newRelPos", "_newPos", "_z"];
                _rotMatrix =[[cos _azi, sin _azi],[-(sin _azi), cos _azi]];
                _newRelPos = [_rotMatrix, _relPos] call _multiplyMatrixFunc;
                if ((count _relPos) > 2) then {_z = _relPos # 2;} else {_z = 0;};
                _newPos = [_posX + (_newRelPos # 0), _posY + (_newRelPos # 1), _z];
                if(_type in WF_C_STATIC_DEFENCE_FOR_COMPOSITIONS)then{
                    _newObj = _type createVehicle _newPos;
                    _newObj enableSimulation false;
                    _newObj enableSimulation true;
                    _newObj addMPEventHandler ['MPKilled', {
                        params ["_unit", "_killer", "_instigator", "_useEffects"];
                        [_unit,_killer] call WFCO_FNC_OnUnitKilled
                    }];
                    _defences pushBack _newObj
                } else {
                    _newObj = _type createVehicle _newPos
                };

                if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 3)) then {
                    [_newObj, resistance, (missionNamespace getVariable Format["WF_%1STRUCTURES",str resistance]) # 3, 3] spawn WFHC_FNC_processAfBase
                };

                _newObj setDir (_azi + _azimuth);

                if (WF_Debug) then {
                    if(_type == ((missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str resistance]) # 3)) then {
                        _marker = format ['ResAF%1', time];
                        createMarker [_marker,getPosATL _newObj];
                        _marker setMarkerTextLocal format ['ResAF%1', time];
                        _marker setMarkerType "mil_box";
                        _marker setMarkerColor 'ColorGreen'
                    }
                }
            };
            [_defences, _pos] call WFHC_FNC_ManningOfResBaseDefense
        };
    };
    _resBasePositions
}

