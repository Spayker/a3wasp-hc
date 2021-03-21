/*
	Create a delegation request.
	 Parameters:
		- Side
		- Groups
		- Spawn positions
		- Teams
		- defence
		- Move In Gunner immidietly or not
*/
params ["_side","_group","_defences"];

["INFORMATION", format["Client_DelegateAIStaticDefence.sqf: Received a delegation request from the server for [%1].", _side]] call WFCO_FNC_LogContent;

if (isNil '_group') then {
    switch (_side) do {
        case west: {
            if(isNil 'WF_HC_DEFENCE_GROUP_WEST') then {
                _group = createGroup [_side, true];
                WF_HC_DEFENCE_GROUP_WEST = _group;
            } else {
                if((count units WF_HC_DEFENCE_GROUP_WEST) > 10) then {
                    _group = createGroup [_side, true];
                    WF_HC_DEFENCE_GROUP_WEST = _group;
                };
            };
        };
        case east: {
            if(isNil 'WF_HC_DEFENCE_GROUP_EAST') then {
                _group = createGroup [_side, true];
                WF_HC_DEFENCE_GROUP_EAST = _group;
            } else {
                if((count units WF_HC_DEFENCE_GROUP_EAST) > 10) then {
                    _group = createGroup [_side, true];
                    WF_HC_DEFENCE_GROUP_EAST = _group;
                };
            };
        };
        case resistance: {
            if(isNil 'WF_HC_DEFENCE_GROUP_GUER') then {
                _group = createGroup [_side, true];
                WF_HC_DEFENCE_GROUP_GUER = _group;
            } else {
                if((count units WF_HC_DEFENCE_GROUP_GUER) > 10) then {
                    _group = createGroup [_side, true];
                    WF_HC_DEFENCE_GROUP_GUER = _group;
                };
            };
        };
    };
};

[_side, _group, _defences] call WFCO_FNC_CreateUnitForStaticDefence;
