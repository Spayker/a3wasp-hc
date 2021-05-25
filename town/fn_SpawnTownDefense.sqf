/*
	spawn defenses in a town.
	 Parameters:
		- Defense Logic.
		- Side.
*/
params ["_town", "_defenseData", "_index", "_side"];
private ["_defense","_entity","_kind","_kinds","_nils","_random","_sideID"];

_sideID = _side call WFCO_FNC_GetSideID;
_defense = "";
_townDefenses = [];

if (count _defenseData > 0) then {
    //--- Retrieve the possible kinds.
    _kinds = _defenseData # 0;

    if (isNil "_kinds") exitWith {};
    //--- At least one type is needed.
    if (count _kinds == 0 || _sideID == WF_C_CIV_ID) exitWith {};

    _nils = [];
    if (count _kinds > 1) then {
        //--- Get a random one.
        while {true} do {
            _random = floor(random count _kinds);
            _kind = missionNamespace getVariable format ["WF_%1_Defenses_%2", _side, _kinds # _random];
            if !(isNil '_kind') then {_defense = _kind # floor(random count _kind);} else {_nils pushBack (_kinds # _random); _kinds = [_kinds, [_random]] call WFCO_FNC_ArrayShift;};
            if (count _kinds == 0 || _defense != "") exitWith {};
        };
    } else {
        //--- Use the default one.
        _kind = missionNamespace getVariable format ["WF_%1_Defenses_%2", _side, _kinds # 0];
        if !(isNil '_kind') then { _defense = _kind # floor(random count _kind); };
    };

    //--- Learn and adapt, remove if nil.
    if (count _nils > 0) then { _defenseData set [0, (_defenseData # 0) - _nils] };

    //--- If found, create a defense.
    if (_defense != "") then {
        _entity = createVehicle [_defense, _defenseData # 1, [], 0, "NONE"];
        _entity addMPEventHandler ['MPKilled', {
            params ["_unit", "_killer", "_instigator", "_useEffects"];
            [_unit,_killer] call WFCO_FNC_OnUnitKilled
        }];
        _entity setDir (_defenseData # 2);
        _entity setVariable ["wf_defense", _entity, true];
        _entity setVariable ["wf_defense_kind", _kinds, true];
        if (count _nils > 0) then { _entity setVariable ["wf_defense_kind",(_defenseData # 0) - _nils] };

        _townDefenses = _town getVariable "wf_town_defenses";
        _townDefenses = _townDefenses - [_defenseData];

        _townDefenses set [_index, [_defenseData # 0, _defenseData # 1, _defenseData # 2, _entity]];
        _town setVariable ["wf_town_defenses", _townDefenses, true];
    }
};

_townDefenses
