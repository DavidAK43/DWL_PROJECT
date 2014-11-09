/*
	File: fn_generateLoot.sqf
	Author: Iceman77
		
	Description:
		- Generate random loot in (on) buildings on the current game world
		- Loot pool includes: 'Uniforms','Vests','Backpacks','Headgear','WeaponsPrimary','WeaponsSecondary','WeaponsHandGuns','WeaponAccessories','general Items'
		- On Altis, at present it can take ~ 20+ minutes to complete initialization as it has to iterate through very large arrays. 
			Also depending on location spread and search radius parameters that were input.
		- On Stratis, at present it takes ~ 5 seconds to complete initialization
	
	Parameters:
		_this select 0: <number> (Optional - 5% default)     Chance that a item will spawn in at any given building position 
		_this select 1: <number> (Optional - 1500m default)  Location spread (Lower the number, higher the performance cost)
		_this select 2: <number> (Optional - 1250m default)  Search radius (Higher the number, higher the performance cost)
		_this select 3: <bool>   (Optional - false default)  Debugging markers - Show Locations, building positions and items markers
		
	Usage Examples:
		_nul = [2, 1500, 1250, true] execVM "DWL.sqf"; 
		_nul = [5, 2000, 1000] spawn DWL_fnc_generateLoot; 
		_nul = [10, 1000, 750, true] call DWL_fnc_generateLoot;
		
	Notes: 
		- The default settings of 1500 & 1250 are my personal favourite. 
		Takes ~25min to initialize loot on Altis, but the positions pools covers essentially all (MOST) buildings on the island.
		
		- Settings 2000 & 1000 / 2000 & 750 are great for faster loot initialization on Altis. The spread is big (not so many locations) and a low search radius.
		
		- Keep the chance parameter between 2 and 10. Recommend no more than 5 IMO. Else it's no fun when every building has loot. I like 2% or probably even 1% (though haven't tried 1%)
		
*/

if (!(isServer)) exitWith {};

private ["_chance","_locSpread","_searchRad","_debug","_locations","_realLocations","_posArray","_houseArray","_itemArray","_buildingsArray","_stop","_start"];

_chance 			= [_this, 0, 5, [-1]] call BIS_fnc_param;
_locSpread 		= [_this, 1, 1500, [-1]] call BIS_fnc_param;
_searchRad 		= [_this, 2, 1250, [-1]] call BIS_fnc_param;
_debug 			= [_this, 3, false, [true]] call BIS_fnc_param;
_locations 		= [];
_realLocations 	= [];
_posArray 		= [];
_houseArray 		= [];
_itemArray 		= [];
_buildingsArray 	= [];

if (_debug) then 
{
	player sideChat "!!! SCRIPT STARTED. !!!";
	
	_start = diag_tickTime;
	
	diag_log "/------Start Time-----/";
	diag_log format ["Start Time: %1", _start]; 
	diag_log "/---------------------/";		
};

"
	getText (_x >> 'type') in ['NameLocal','NameCity','NameCityCapital','NameVillage'] &&
	{_locations pushBack (getArray (_x >> 'position'));false}
" configClasses (configFile >> "CfgWorlds" >> worldName >> "Names");

"
	getNumber (_x >> 'scope') >= 2 && 
	{getText (_x >> 'vehicleClass') in ['ItemsUniforms','ItemsVests','ItemsHeadgear','WeaponsPrimary','WeaponsSecondary','WeaponsHandGuns','WeaponAccessories','Items','Backpacks'] && 
	{_itemArray pushBack (configName _x);
	 true
		}
	}
" configClasses (configFile >> "CfgVehicles");

"
	getNumber (_x >> 'scope') >= 2 && 
	{getNumber (_x >> 'type') in [256,16,2*256,3*256,6*256] && 
	{_itemArray pushBack (configName _x);
	 true
		}
	}
" configClasses (configFile >> "CfgMagazines");

if (_debug) then 
{
	player globalChat "!!! CREATING CENTERS. PLEASE WAIT... !!!";	
};

{

	private ["_loc","_index","_badLocation"];
	
	_loc = _x;
	_index = _forEachIndex;
	_badLocation = false;	
	
	{
		if (_index == 0) exitWith {
			_realLocations pushBack _loc;
		};	
		if (_loc distance _x <= _locSpread) exitWith {
			_badLocation = true;
		};	
	} forEach _realLocations;
	
	if (!(_badLocation)) then {
		_realLocations pushBack _loc;
	};
	
} forEach _locations;

{
	private ["_loc","_goodSpot","_houseArray"];
	_loc = _x;
	_houseArray = nearestObjects [ _loc, [ "House_F" ], _searchRad ];
	{
		if (!(_x in _buildingsArray)) then {
			_buildingsArray pushBack _x;
		};
	} forEach _houseArray;
	
	if (_debug) then {
		private ["_mrk"];
		_mrk = createMarker [ format ["loc_M%1", random 1000], _loc ]; 
		_mrk setMarkerShape "ICON"; 
		_mrk setMarkerType "mil_dot";
		_mrk setMarkerColor "colorRed"; 	
		_mrk setMarkerSize [1,1]; 
	};	
} forEach _realLocations;

if (_debug) then 
{
	player sideChat "!!! CREATING CENTERS DONE. !!!";
	player globalChat "!!! CREATING BUILDING POSITIONS. PLEASE WAIT... !!!";
};

{	
	private ["_positions","_index"];
	
	_positions = [_x] call BIS_fnc_buildingPositions;	
	if (!(_positions isEqualTo [])) then {
	
		{
			_posArray pushBack _x;			
			if (_debug) then {
				private ["_mrk"];
				
				_mrk = createMarker [ format ["Pos_M%1", random 1000], _x ]; 
				_mrk setMarkerShape "ICON"; 
				_mrk setMarkerType "mil_dot"; 
				_mrk setMarkerColor "colorBlue"; 
				_mrk setMarkerSize [0.5,0.5]; 			
			};			
		} forEach _positions;		
	};
} forEach _buildingsArray;

if (_debug) then 
{
	player sideChat "!!! CREATING BUILDING POSITIONS DONE. !!!";
	player globalChat "!!! CREATING ITEMS. PLEASE WAIT... !!!";
};

{	
	private ["_number","_randItem","_weaponHolder","_color"];
	
	_number = floor random 100;
	_diff = 100 - _chance;
	
	if (_number >= _diff) then {
	
		_randItem = ( _itemArray select floor ( random ( count _itemArray ) ) );
		if (isClass (configFile >> "cfgMagazines" >> _randItem)) then {
		
			_weaponHolder = createVehicle [ "WeaponHolderSimulated", _x, [], 0, "CAN_COLLIDE" ]; 
			_weaponHolder addMagazineCargoGlobal [ _randItem, 2 ];
			_color = if (_debug) then {"colorRed";};//Magazines
			
		} else {
		
			private ["_class"];
			
			_class = getText (configFile >> "cfgVehicles" >> _randItem >> "vehicleClass");	
			if (_class isEqualTo "Backpacks") then {
			
				_weaponHolder = createVehicle [ "WeaponHolderSimulated", _x, [], 0, "CAN_COLLIDE" ]; 
				_weaponHolder addBackPackCargoGlobal [ _randItem, 1 ];
				_color = if (_debug) then {"colorOrange";};// backpack	
				
			} else {	
			
				_weaponHolder = createVehicle [_randItem, _x, [], 0, "CAN_COLLIDE"];	
				_color = if (_debug) then {"colorGreen";};// weapon, accessory, gear
				
			};
		};
		
		if (_debug && {!(isNull _weaponHolder)}) then {	
			private ["_mrk"];
			
			_mrk = createMarker [ format ["Item_M%1", random 1000], getPosATL _weaponHolder ]; 
			_mrk setMarkerShape "ICON"; 
			_mrk setMarkerType "mil_triangle"; 
			_mrk setMarkerColor _color; 
			_mrk setMarkerSize [0.5,0.5]; 
			
		};		
	};	
} forEach _posArray;

if (_debug) then 
{
	player sideChat "!!! CREATING ITEMS DONE. !!!";
	player sideChat "!!! SCRIPT DONE. !!!";
	
	_stop = diag_tickTime;
	
	diag_log "/------End Time-----/";
	diag_log format ["End Time: %1", _stop]; 
	diag_log "/-------------------/";
	
	diag_log "/-------------Total Time----------/";
	diag_log format ["Total Time: %1", _stop - _start]; 
	diag_log "/---------------------------------/";	
};

true

