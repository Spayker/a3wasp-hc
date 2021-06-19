params["_cram"];
private["_cram","_range","_incoming","_target","_targetTime"];

_range = 2000;
while{ alive _cram } do {

    _incoming = [];
    {
        _incoming = _incoming + (_cram nearObjects[_x, _range])
    } forEach WF_ARTY_SHELL_TYPES;

    if(count _incoming > 0) then {

        _target = selectRandom _incoming;


        if!(isNull _target) then {

            _oldDistance = _cram distance _target;
            sleep 0.1;
            _dirTarget = direction _target;
                _fromTarget = _target getDir _cram;

            if(_dirTarget < _fromTarget + 25 && _dirTarget > _fromTarget - 25 && ((getPos _target) select 2) > 20 && alive _target && ( (_cram distance _target) < _oldDistance ) )then{
            while{alive _cram && alive _target}do{
                    _cram doWatch _target;
              if((_cram weaponDirection (currentWeapon _cram)) select 2 > 0.15)then{
                _ammoCram = _cram ammo (currentMuzzle (gunner _cram));
                if(_ammoCram == 0) then { _cram setVehicleAmmo 1 };
                      _cram fireAtTarget[_target,(currentWeapon _cram)];
              };
            };
                };

          if(alive _target && alive _cram && _target distance _cram < _range && _target distance _cram > 40 && (getPos _target) # 2 > 10 && ( (_cram distance _target) < _oldDistance))then{
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
    } else {
        _ammoCram = _cram ammo (currentMuzzle (gunner _cram));
        if(_ammoCram > 0) then { _cram setVehicleAmmo 0 };
        sleep 0.1
    }
}

