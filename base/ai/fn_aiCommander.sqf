Private ['_side', '_commanderGroup', '_isAiCommanderRunning'];

while {!WF_GameOver} do {
    sleep 90;
    {
        _side = _x;
        _logic = (_side) Call WFCO_FNC_GetSideLogic;
        _isFirstLostTeam = _logic getVariable ["wf_isFirstOutTeam", false];

        if (_isFirstLostTeam) then {
           [_side] call WFHC_fnc_aiCleanUpHcGroups
        } else {
        // get team commander
        _commanderGroup = (_side) Call WFCO_FNC_GetCommanderTeam;
            diag_log format ['fn_aiCommander.sqf: _commanderGroup - %1', _commanderGroup];
        if(isNull _commanderGroup) then {
            // let's run ai commander for current side

                [_side, _logic] spawn {
                    params ['_side', '_logic'];
                private ['_sideId', '_factories','_highCommandGroups','_waypoints'];

                _sideId = _side Call WFCO_FNC_GetSideID;

                // get high command groups
                _highCommandGroups = [_side] call WFCO_FNC_getHighCommandGroups;
                    diag_log format ['fn_aiCommander.sqf: _highCommandGroups - %1', _highCommandGroups];
                if(count _highCommandGroups > 0) then {
                    // time to give orders for HC groups
                        { [_x, _logic] call WFHC_fnc_aiComSetWaypoint } forEach _highCommandGroups
                        };

                    // deploy additional structures
                    [_side, _logic] call WFHC_fnc_aiBaseBuildStructures;

                // define how many groups can be ordered
                    [_side] call WFHC_fnc_aiBuildHcGroups;

                // perform upgrades
                [_side] remoteExecCall ["WFSE_FNC_aiComUpgrade", 2];
            }
        }
        }
    } forEach WF_PRESENTSIDES
}


