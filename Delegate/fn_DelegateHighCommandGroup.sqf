params ["_side", "_selectedGroupTemplate", "_position", "_direction"];

["INFORMATION", Format["fn_DelegateHighCommandGroup.sqf: Received a delegation request from the server for [%1].", _selectedGroupTemplate]] Call WFCO_FNC_LogContent;

[_side, _selectedGroupTemplate, _position, _direction] call WFHC_fnc_CreateHighCommandGroup