params ["_building", "_side"];
private ["_posBuilding", "_lastCheck", "_maxTeams", "_teams"];

_posBuilding = getPos _building;
_lastCheck = 0;
_maxTeams = missionNamespace getVariable "WF_C_BASE_PATROLS_INFANTRY";
_teams = 0;

while {!WF_GameOver} do {

	if(alive _building) then {
		if(_teams < _maxTeams) then {

			_currentUpgrades = (_side) Call WFCO_FNC_GetSideUpgrades;
			_currentLevel = _currentUpgrades select WF_UP_GEAR;
			
			[_building,_side,missionNamespace getVariable Format['WF_%1BASEPATROLS_%2',_side,_currentLevel]] spawn {
			    params ["_site", "_side", "_units"];
				private ['_direction','_distance','_index','_position','_side','_site','_type','_units'];
				
				_type = typeOf _site;
				_index = (missionNamespace getVariable Format["WF_%1STRUCTURENAMES",str _side]) find _type;
				_distance = (missionNamespace getVariable Format["WF_%1STRUCTUREDISTANCES",str _side]) select _index;
				_direction = (missionNamespace getVariable Format["WF_%1STRUCTUREDIRECTIONS",str _side]) select _index;
				_position = [getPos _site,_distance,getDir _site + _direction] Call WFCO_FNC_GetPositionFrom;

				[_site, _units, _position, _side, WF_Logic] call WFHC_FNC_DelegateBasePatrolAI
			};
		    _teams = _teams + 1;
		};
	};
	
	if(isNull _building || !(alive _building)) then {
		_buildings = (_side) Call WFCO_FNC_GetSideStructures;
		_sorted = [_posBuilding, _buildings] Call WFCO_FNC_GetClosestEntity;

		_nearby = false;
		if (!isNull _sorted) then {
			if (_sorted distance _posBuilding < 400) then {_nearby = true};
		};

        [_nearby] call WFHC_FNC_RemoveGroup;
        _teams = _teams - 1
	};
	sleep 300;
};

















