/* Description: Creates Defenses. */
params ["_type","_side","_position","_direction","_manned",["_playerUID", ""], "_playerID"];
private ["_buildings","_defense","_isArtillery","_sideID","_area","_crewUnits","_gunnerType"];

_sideID = (_side) call WFCO_FNC_GetSideID;

_area = [_position,((_side) call WFCO_FNC_GetSideLogic) getVariable "wf_basearea"] call WFCO_FNC_GetClosestEntity4;

_defense = createVehicle [_type, _position, [], 0, "NONE"];
_defense call WFCO_FNC_BalanceInit;

_defense setDir _direction;
_defense setVariable ["side", _side];
_defense setVariable ["playerUID", _playerUID];

["INFORMATION", format ["Construction_StationaryDefense.sqf: [%1] Defense [%2] has been constructed.", str _side, _type]] call WFCO_FNC_LogContent;

_defense setVariable ["wf_defense", true]; //--- This is one of our defenses.

call Compile format ["_defense addEventHandler ['Killed',{[_this # 0,_this select 1,%1] spawn WFCO_FNC_OnUnitKilled; [_this # 0] spawn WFCO_FNC_KillStaticDefenseCrew;}]",_sideID];
_defense addEventHandler ['Deleted',{[_this # 0] call WFCO_FNC_KillStaticDefenseCrew;}];

//--Check if vehicle is arty vehicle and add EH--
{
    if(typeOf _defense == (_x # 0)) exitWith {
		[_defense, ["Fired", {
        	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

			if(isPlayer _gunner || _gunner == (missionNamespace getVariable ["wf_remote_ctrl_unit", objNull])) then {
				deleteVehicle _projectile;
			};
        }]] remoteExec ["addEventHandler", -2, true];
    };
} forEach (missionNamespace getVariable [format['WF_%1_ARTILLERY_CLASSNAMES', _side], []]);

if (_manned && _defense emptyPositions "gunner" > 0 && (((missionNamespace getVariable "WF_C_BASE_DEFENSE_MAX") > 0))) then {
	private ["_check","_team"];
	_team = _area getVariable "DefenseTeam";

	if (isNil '_team') then {
        _team = createGroup [_side, true];
        _area setVariable ["DefenseTeam", _team];
    } else {
        if(side _team != _side) then {
            _team = createGroup [_side, true];
        };
        if((count units _team) > 10) then {
            _team = createGroup [_side, true];
        };
        _area setVariable ["DefenseTeam", _team];
    };

	private _specDefenseIndex = (WF_C_ADV_AIR_DEFENCE # 0) find (typeOf _defense);
	if(_specDefenseIndex > -1) then {
	    _gunnerType = missionNamespace getVariable format ["WF_%1SOLDIER", _side];
		_crewUnits = [_defense, [_gunnerType, "turret"], true, true] call BIS_fnc_initVehicleCrew;

		{
			[_x, _gunnerType, _team, _position, _side call WFCO_FNC_GetSideID] spawn WFCO_fnc_InitManUnit;
			_x setSkill 1;
			[_x, WF_C_GAMEPLAY_MISSILES_RANGE, getPosATL _defense] spawn WFCO_FNC_RevealArea;

			[str _side, 'UnitsCreated', 1] call WFCO_FNC_UpdateStatistics;
		} forEach _crewUnits;

		_defense setVariable ["crewUnits", _crewUnits, true];

	    _defense addeventhandler ["fired", {
			params ["_unit"];

			[_unit] spawn {
				_unit = _this # 0;
				_specDefenseIndex = (WF_C_ADV_AIR_DEFENCE # 0) find (typeOf _unit);
        		_unit setVehicleAmmo 0;
        		sleep ((WF_C_ADV_AIR_DEFENCE # 1) # _specDefenseIndex);
        		_unit setVehicleAmmo 1;
            };
        }];

		if ((missionNamespace getVariable "WF_C_GAMEPLAY_MISSILES_RANGE") != 0) then {
            _defense addeventhandler ["fired", { _this spawn WFCO_FNC_HandleIncomingMissile }]
		} //--- Max missile range.
	} else {
		if!([typeOf _defense] in (missionNamespace getVariable [format['WF_%1_ARTILLERY_CLASSNAMES', _side], []])) then {
			_defense addeventhandler ["fired", {
				params["_unit"];

				_crewUnit = crew _unit;
				if(count _crewUnit > 0) then {
					_crewLieader = leader (_crewUnit # 0);

					if(!isNull _crewLieader && !isPlayer _crewLieader) then {
						if(_unit ammo (primaryWeapon _unit) <= 0) then { _unit setvehicleammo 1 }
					}
				}
			}]
		}
	};

	//if (_type in ['CUP_WV_B_CRAM_OPFOR', 'B_AAA_System_01_F_OPFOR', 'CUP_WV_B_CRAM', 'B_AAA_System_01_F']) then {
    //    [_defense] spawn WFSE_FNC_initCram
	//};


	if (_specDefenseIndex == -1) then {
        WF_static_defenses pushBack [_defense, _side, _team, time]
	};
};

[_side, _type,  _position, _direction, _manned, _playerUID, _playerID, _defense] remoteExecCall ["WFSE_FNC_processBaseDefense", 2]
