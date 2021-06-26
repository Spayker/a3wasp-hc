Params ['_side', '_logic'];
Private ['_areas', '_area', '_additionalBaseStructurePositions', '_availableBasePosition', '_sideSupplies', '_factories'];

_areas = _logic getVariable "wf_basearea";

{
    _area = _x;
    _additionalBaseStructurePositions = _area getVariable ['additionalBaseStructurePositions', []];
    _dir = _area getVariable ['baseDirection', 0];
    _sideSupplies = _side Call WFCO_FNC_GetSideSupply;
    // [_twnSide, 750] call WFCO_FNC_ChangeSideSupply;

    _shallBuildHeavyFactory = true;
    _shallBuildAirFactory = true;

    _factories = [];
    {
        _factories = _factories + ([_side, missionNamespace getVariable format ["WF_%1%2TYPE", str _side, _x], (_side Call WFCO_FNC_GetSideStructures)] call WFCO_FNC_GetFactories);
    } forEach WF_C_BASE_PRODUCTION_STRUCTURE_NAMES;

    {
        _factory = _x;
        _structureType = _factory getVariable ['wf_structure_type', ''];
        switch (_structureType) do {
            case 'Heavy': { _shallBuildHeavyFactory = false };
            case 'Aircraft': { _shallBuildAirFactory = false };
        };
    } forEach _factories;

    _structuresNames = missionNamespace getVariable Format ['WF_%1STRUCTURENAMES', str _side];
    _structuresCosts = missionNamespace getVariable Format["WF_%1STRUCTURECOSTS", str _side];

    if (_shallBuildHeavyFactory && count _additionalBaseStructurePositions > 0) then {
        _availPositionArray = _additionalBaseStructurePositions # 0;
        _availableBasePosition = _availPositionArray # 0;
        _relDir = _availPositionArray # 1;
        [_structuresNames # 4, _side, _availableBasePosition, (_dir - _relDir), 4, -1] call WFHC_FNC_MediumSite;
        [_side, -(_structuresCosts # 4)] Call WFCO_FNC_ChangeSideSupply;
        _additionalBaseStructurePositions deleteAt 0
    };

    if (_shallBuildAirFactory && count _additionalBaseStructurePositions > 0) then {
        _availPositionArray = _additionalBaseStructurePositions # 0;
        _availableBasePosition = _availPositionArray # 0;
        _relDir = _availPositionArray # 1;

        [_structuresNames # 5, _side,_availableBasePosition,(_dir - _relDir),5,-1] call WFHC_FNC_SmallSite;
        [_side, -(_structuresCosts # 5)] Call WFCO_FNC_ChangeSideSupply;
        _additionalBaseStructurePositions deleteAt 0
    };

    _area setVariable ['additionalBaseStructurePositions', _additionalBaseStructurePositions];

} forEach _areas
