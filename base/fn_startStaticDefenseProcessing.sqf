private ['_procesStaticDefenses', '_repeats'];

_procesStaticDefenses = {

    WF_static_defenses = WF_static_defenses - [objNull];

    for "_i" from 0 to ((count WF_static_defenses) - 1) step 1 do {

        _defense = (WF_static_defenses # _i) # 0;
        _side = (WF_static_defenses # _i) # 1;
        _team = (WF_static_defenses # _i) # 2;
        _time = (WF_static_defenses # _i) # 3;
        _repeats = -1;

        if(time > _time) then {
            if (alive _defense) then {
                if (isNull(gunner _defense) || !alive (gunner _defense)) then {

                    _buildings = (_side) call WFCO_FNC_GetSideStructures;
                    _closest = ['BARRACKSTYPE',_buildings,WF_C_BASE_DEFENSE_MANNING_RANGE,_side,_defense] call WFCO_FNC_BuildingInRange;
                    _canMann = alive _closest;

                    //--Second check if we have a barracks in WF_C_BASE_DEFENSE_MANNING_RANGE + WF_C_BASE_DEFENSE_MANNING_RANGE_EXT * 2 (DIAMETER)--
                    //--and any building in this area--
                    if(!_canMann) then {
                        _closest = ['BARRACKSTYPE',_buildings,
                                   (WF_C_BASE_DEFENSE_MANNING_RANGE + (WF_C_BASE_DEFENSE_MANNING_RANGE_EXT * 2)),
                                   WF_Client_SideJoined,_defense] call WFCO_FNC_BuildingInRange;
                        _canMann = (alive _closest && alive([position _defense,_buildings] call WFCO_FNC_GetClosestEntity5));
                    };

                    if (_canMann) then {
                        _type = typeOf _closest;
                        _index = (missionNamespace getVariable format["WF_%1STRUCTURENAMES",str _side]) find _type;
                        _distance = (missionNamespace getVariable format["WF_%1STRUCTUREDISTANCES",str _side]) # _index;
                        _direction = (missionNamespace getVariable format["WF_%1STRUCTUREDIRECTIONS",str _side]) # _index;
                        _position = [getPosATL _closest,_distance,getDir (_closest) + _direction] call WFCO_FNC_GetPositionFrom;

                        _gunnerType = missionNamespace getVariable format ["WF_%1SOLDIER", _side];

                        ["INFORMATION", format ["fn_HandleDefense.sqf: [%1] New or old unit will be dispatched to a [%2] defense.",
                        str _side, format["%1 %2", typeOf _defense, _defense]]] call WFCO_FNC_LogContent;
                        [_side, _team, [_defense]] call WFHC_FNC_DelegateAIStaticDefence;
                        _repeats = 0
                    } else {
                        if(_repeats == 0) then {
                            ["INFORMATION", format["Server_HandleDefense.sqf: Can not to create unit for %1, no barracks.", format["%1 %2", typeOf _defense, _defense]]] call WFCO_FNC_LogContent;
                            _repeats = 1
                        }
                    }
                };
                _time = _time + WF_C_BASE_DEFENSE_MANNING_TIMEOUT;
                _updatedDefenseStatus = [_defense, _side, _team, _time];
                WF_static_defenses set [_i, _updatedDefenseStatus]
            } else {
                WF_static_defenses set [_i, objNull]
            }
        }
    }
};

while {!WF_GameOver} do {
	[] call _procesStaticDefenses;
	sleep 15
}