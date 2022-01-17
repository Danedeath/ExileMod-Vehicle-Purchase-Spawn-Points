/**
 * ExileServer_system_trading_network_purchaseVehicleRequest
 *
 * Exile Mod
 * www.exilemod.com
 * © 2015 Exile Mod Team
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
 */
 
private["_sessionID","_parameters","_vehicleClass","_pinCode","_playerObject","_salesPrice","_playerMoney","_position","_vehicleObject","_logging","_traderLog","_responseCode","_spawnObjects","_disableRadius", "_dirAir", "_dirOther", "_searchRadius", "_errorMessage", "_nObjects", "_lenSpawnObjects", "_findEmpty", "_throwError"];
_sessionID    = _this select 0;
_parameters   = _this select 1;
_vehicleClass = _parameters select 0;
_pinCode      = _parameters select 1;
_throwError   = 0;
try 
{
	_playerObject = _sessionID call ExileServer_system_session_getPlayerObject;
	if (isNull _playerObject) then
	{
		throw 1;
	};
	if !(alive _playerObject) then
	{
		throw 2;
	};
	if (_playerObject getVariable ["ExileMutex",false]) then
	{
		throw 12;
	};
	_playerObject setVariable ["ExileMutex", true];
	if !(isClass (missionConfigFile >> "CfgExileArsenal" >> _vehicleClass) ) then
	{
		throw 3;
	};
	_salesPrice = getNumber (missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "price");
	if (_salesPrice <= 0) then
	{
		throw 4;
	};
	_playerMoney = _playerObject getVariable ["ExileMoney", 0];
	if (_playerMoney < _salesPrice) then
	{
		throw 5;
	};
	if !((count _pinCode) isEqualTo 4) then
	{
		throw 11;
	};

	// check to see if vehicle is a ship, if so then spawn in in the water
	if (_vehicleClass isKindOf "Ship") then {
		_position = [(getPosATL _playerObject), 80, 10] call ExileClient_util_world_findWaterPosition;
		if (_position isEqualTo []) then 
		{
			throw 13;
		};
		_vehicleObject = [_vehicleClass, _position, (random 360), false, _pinCode] call ExileServer_object_vehicle_createPersistentVehicle;

	} else { 

		_spawnObjects    = [ // objects available for spawning vehicles

			// most common two spawn objects
			"VR_Area_01_circle_4_yellow_F",	
			"VR_Area_01_square_4x4_yellow_F",
			"Land_HelipadCircle_F",

			"Land_HelipadSquare_F",
			"Land_HelipadCivil_F",
			"Land_HelipadEmpty_F",
			"Land_JumpTarget_F"
		]; 		

		_safeRadius     = 5;                   // radius around the spawn object where it looks for room, must be 5 or higher
		_disableRadius  = 0;                   // set to 1 if you want vehicles to only spawn at the exact coords of your spawn object, not recommended better to reduce _safeRadius
		_dirAir         = 30.180;              // set rotation of air vehicle spawning, default = random
		_dirOther       = (random 360);        // set rotation of all other vehicles spawning, default = random
		_searchRadius	= 110;                 // set the radius to search for _spawnObjects based on the players current location
		
		// (toast)message to player when there is no room to spawn at any of the available locations
		_errorMessage   = "There is no room to safely spawn this vehicle, ask a player to move their vehicle!"; 

		// If you want to ignore a specific spawn object then add something like this for a specific vehicle type
		// if (_vehicleClass isKindOf "Air") then { _spawnObjects deleteAt 0; };
		
		// find a type of nearest object from the list of objects available...
		{
			_objects = nearestObjects  [_playerObject, [_x], _searchRadius];
			if ((count _objects) >= 1) then {

				_nObjects append _objects;

			};
		} forEach _spawnObjects;
		
		_lenSpawnObjects = count _nObjects;

		//diag_log format ["[VehPurch] Request for vehicle %1, found %2 locations.", _vehicleClass, str (count _nObjects)];

		if (_lenSpawnObjects isEqualTo 0) then {	// if a _spawnObject is not available, default to the original spawn system

			//diag_log format ["[VehPurch] Request for vehicle %1, found 0 locations found, fallback used.", _vehicleClass];
			_position = (getPos _playerObject) findEmptyPosition [10, 175, _vehicleClass];
			if (_position isEqualTo []) then 
			{
				throw 13;
			};
			_vehicleObject = [_vehicleClass, _position, (random 360), true, _pinCode] call ExileServer_object_vehicle_createPersistentVehicle;

		} else {
			// get a list of object from the names provided

			_lenSpawnObjects = _lenSpawnObjects - 1;
			{
				// Current result is saved in variable _x
				// diag_log format ["[VehPurch] Getting position for %1::%2",  typeName _x, _x];

				_nObject  = _x;
				_position = getPos _nObject;
	
				// ensure that the last position is a valid positional array
				if ([_position, []] call BIS_fnc_areEqual and _forEachIndex isEqualTo _lenSpawnObjects) then {
					[_sessionID, "toastRequest", ["ErrorTitleAndText", ["Error: Unable to get the position of the Spawn Object."]]] call ExileServer_system_network_send_to;
					_throwError = 1;
					break;
				};

				// provide an error message if the position is empty and the last available location point is being used
				_findEmpty = _position findEmptyPosition [0, _safeRadius, _vehicleClass];
				if ([_findEmpty, []] call BIS_fnc_areEqual and _forEachIndex isEqualTo _lenSpawnObjects) then {
					[_sessionID, "toastRequest", ["ErrorTitleAndText", [_errorMessage]]] call ExileServer_system_network_send_to;
					_throwError = 1;
					break;
				};

				// ensure that _findEmpty is not an empty array, if so attempt to spawn a vehicle at the provided location
				if (_findEmpty isNotEqualTo []) then {	
					
					_isEmpty = _findEmpty isFlatEmpty [-1, -1, -1, -1, -1, false, _nObject];
					if ([_isEmpty, []] call BIS_fnc_areEqual and _forEachIndex isEqualTo _lenSpawnObjects) then
					{
						[_sessionID, "toastRequest", ["ErrorTitleAndText", [_errorMessage]]] call ExileServer_system_network_send_to;
						_throwError = 1;
					};
					
					if (_isEmpty isNotEqualTo []) then {
						
						_finalPos = if (_disableRadius isEqualTo 1) then { _position } else { _findEmpty };

						switch (true) do {
							case (_vehicleClass isKindOf "Air"): {
								_vehicleObject = [_vehicleClass, _finalPos, _dirAir, true, _pinCode] call ExileServer_object_vehicle_createPersistentVehicle;
								break;
							};
							default {
								_vehicleObject = [_vehicleClass, _finalPos, _dirOther, true, _pinCode] call ExileServer_object_vehicle_createPersistentVehicle;
								break;
							};
						};
					} else { continue; };
				};

			} forEach _nObjects;
		};
	};
		

	if (_throwError isEqualTo 0) then
    {
		//added 3rd parameter "true" Pro
		_vehicleObject setVariable ["ExileOwnerUID", (getPlayerUID _playerObject), true];
		_vehicleObject setVariable ["ExileIsLocked",0];
		_vehicleObject lock 0;
		_vehicleObject call ExileServer_object_vehicle_database_insert;
		_vehicleObject call ExileServer_object_vehicle_database_update;
		_playerMoney = _playerMoney - _salesPrice;
		_playerObject setVariable ["ExileMoney", _playerMoney, true];
		format["setPlayerMoney:%1:%2", _playerMoney, _playerObject getVariable ["ExileDatabaseID", 0]] call ExileServer_system_database_query_fireAndForget;
		[_sessionID, "purchaseVehicleResponse", [0, netId _vehicleObject, _salesPrice]] call ExileServer_system_network_send_to;

		_logging = getNumber(configFile >> "CfgSettings" >> "Logging" >> "traderLogging");
		if (_logging isEqualTo 1) then
		{
			_traderLog = format ["PLAYER: ( %1 ) %2 PURCHASED VEHICLE %3 FOR %4 POPTABS | PLAYER TOTAL MONEY: %5",getPlayerUID _playerObject,_playerObject,_vehicleClass,_salesPrice,_playerMoney];
			"extDB3" callExtension format["1:TRADING:%1",_traderLog];
		};
	};

} catch {
	_responseCode = _exception;
	[_sessionID, "purchaseVehicleResponse", [_responseCode, "", 0]] call ExileServer_system_network_send_to;
};

if !(isNull _playerObject) then 
{
	_playerObject setVariable ["ExileMutex", false];
};
true
