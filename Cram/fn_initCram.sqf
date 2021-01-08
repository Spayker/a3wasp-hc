params["_cram"];
private["_cram","_range","_incoming","_target","_targetTime"];

_range = 1500;
while{ alive _cram } do {

    _incoming = (_cram nearObjects["MissileBase", _range]);
    {
        if (typeOf _x != 'ammo_Missile_Cruise_01') then { _incoming deleteAt _forEachIndex }
    } forEach _incoming;

    if(count _incoming > 0) then {

        _target = selectRandom _incoming;

        if!(isNull _target) then {
            _artyVehicleSide = civilian;
            _shotParents = getShotParents _target;

            if(count _shotParents > 0) then { _artyVehicleSide = side (_shotParents # 0) };

            if (_artyVehicleSide != side _cram) then {

                _fromTarget = _target getDir _cram;
                _dirTarget = direction _target;

                if(_dirTarget < _fromTarget + 25 && _dirTarget > _fromTarget - 25 && ((getPos _target) # 2) > 20 && alive _target) then {
                  _targetTime = time + 0.5;
                  while{alive _cram && alive _target && _targetTime > time} do {
                    _cram doWatch _target;
                    if((_cram weaponDirection (currentWeapon _cram)) # 2 > 0.15) then {
                      _cram fireAtTarget[_target,(currentWeapon _cram)];
                      sleep 0.5
                    }
                  }
                };

                if(alive _target && alive _cram && _target distance _cram < _range && _target distance _cram > 40 && (getPos _target) # 2 > 10)then{
                  _null = [_target,_cram]spawn{
                      private["_target","_cram","_expPos","_exp"];
                      _target = _this # 0;
                      _cram = _this # 1;
                      _expPos = getPos _target;
                      deleteVehicle _target;
                      _exp = "helicopterexplosmall" createVehicle _expPos
                  }
                }
            }
        };
        sleep 1
    } else { sleep 5 }
}

