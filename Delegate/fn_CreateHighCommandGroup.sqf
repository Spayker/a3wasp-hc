params ["_player", "_selectedGroupTemplate", "_position", "_direction"];

[_side, _selectedGroupTemplate, _position, _direction] spawn {
    params ["_side", "_selectedGroupTemplate", "_position", "_direction"];

    _isVehicle = true;
    _sideID = _side Call WFCO_FNC_GetSideID;
    _unitGroup = createGroup [_side, true];
    _isCommanderAssigned = false;
    _commanders = [];
    _gunners = [];
    {
            _c = missionNamespace getVariable _x;
            sleep (_c # QUERYUNITTIME);

            if (_x isKindOf "Man") then {
                _isVehicle = false;
                [_x, _unitGroup, _position, _sideID] Call WFCO_FNC_CreateUnit;
                [str _side,'UnitsCreated',1] Call WFCO_FNC_UpdateStatistics;
            } else {
                _vehicle = [_x, _position, _sideID, 0, false, nil, nil, nil] Call WFCO_FNC_CreateVehicle;
                _unitGroup reveal _vehicle;
                createVehicleCrew _vehicle;
                [str _side,'UnitsCreated',1] Call WFCO_FNC_UpdateStatistics;
                {
                    [_x, typeOf _x,_unitGroup,_position,_sideID] spawn WFCO_FNC_InitManUnit;

                    private _classLoadout = missionNamespace getVariable Format ['WF_%1ENGINEER', _side];
                    _x disableAI "RADIOPROTOCOL";
                    _x setUnitLoadout _classLoadout;
                    _x setUnitTrait ["Engineer",true];
                    [str _side,'UnitsCreated',1] Call WFCO_FNC_UpdateStatistics;

                    if (_x == commander _vehicle) then { _commanders pushBack _x };
                    if (_x == gunner _vehicle) then { _gunners pushBack _x };

                } forEach crew _vehicle;
                (crew _vehicle) joinSilent (_unitGroup);
        }
    } forEach _selectedGroupTemplate;

    if (count _commanders > 0) then {
        {
            if (_isCommanderAssigned) then {
                _x setUnitRank 'SERGEANT'
            } else {
                _x setUnitRank 'LIEUTENANT';
                _unitGroup selectLeader _x
            }
        } foreach _commanders
    } else {
        if (count _gunners > 0) then {
            {
                if (_isCommanderAssigned) then {
                    _x setUnitRank 'SERGEANT'
                } else {
                    _x setUnitRank 'LIEUTENANT';
                    _unitGroup selectLeader _x
                }
            } foreach _gunners
        }
    };

    _unitGroup allowFleeing 0;
    _unitGroup setCombatMode "YELLOW";

    if (_isVehicle) then {
		_unitGroup setFormation "FILE";
		_unitGroup setBehaviour "COMBAT";
	} else {
		_unitGroup setBehaviour "AWARE";
	};
    _unitGroup setSpeedMode "FULL";
    _unitGroup enableAttack false;

    _unitGroup setVariable ["isHighCommandPurchased",true, true];
}