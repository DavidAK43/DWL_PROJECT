/*
    File: fn_generateLoot.sqf
    Author: Iceman77
    
    Description:
        - Generate random loot in (on) buildings on the current game world
        - Loot pool includes: 'Uniforms','Vests','Backpacks','Headgear','WeaponsPrimary','WeaponsSecondary','WeaponsHandGuns','WeaponAccessories','general Items'
        - On Altis, at present it takes ~ 20 minutes to complete initialization as it has to iterate through very large arrays
        - On Stratis, at present it takes ~ 5 seconds to complete initialization
        - Any optimizations are welcomed!! 
    
    Parameters:
        _this select 0: <number> (Optional - Default: 5%) Chance that a item will spawn in at any given building position 
        _this select 1: <bool> (Optional, default: false) Debugging markers - Show Locations, building positions and items markers
        
    Usage Examples:
        _nul = [10,true] execVM "generateLoot.sqf";// Script
        _nul = [10,true] spawn DRW_fnc_generateLoot;// Function
        _nul = [10,true] call DRW_fnc_generateLoot;// Function

*/

if (!(isServer)) exitWith {};

private ["_chance","_debug","_locations","_posArray","_houseArray","_itemArray","_buildingsArray"];

_chance = [_this, 0, 5, [-1]] call BIS_fnc_param;
_debug = [_this, 1, false, [true]] call BIS_fnc_param;
_locations = [];
_posArray = [];
_houseArray = [];
_itemArray = [];
_buildingsArray = [];

"
    _locations pushBack (getArray (_x >> 'position'));
    true
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

if (_debug) then {
    player globalChat "!!! CREATING CENTERS. PLEASE WAIT... !!!";
};

{
    private ["_loc","_tooClose","_houseArray"];
    
    _loc = _x;
    _tooClose = false;
    
    if (_forEachIndex > 0) then {
    
        {
            if (_x distance _loc <= 500) then {
                _tooClose = true;
            };
        } forEach _buildingsArray;
        
    };
    
    if (!_tooClose) then {
    
        _houseArray = nearestObjects [ _loc, [ "House_F" ], 500 ];
        
        if (count _houseArray > 0) then {
        
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
            
        };
        
    };
    
} forEach _locations;

if (_debug) then {
    player sideChat "!!! CREATING CENTERS DONE. !!!";
    player globalChat "!!! CREATING BUILDING POSITIONS. PLEASE WAIT... !!!";
};

{    
    private ["_positions","_index"];
    
    _positions = [_x] call BIS_fnc_buildingPositions;
    
    if ( count _positions > 0 ) then {
    
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

if (_debug) then {
    player sideChat "!!! CREATING BUILDING POSITIONS DONE. !!!";
    player globalChat "!!! CREATING ITEMS. PLEASE WAIT... !!!";
};

{    
    private ["_number","_randItem","_weaponHolder"];
    
    _number = [0,100] call BIS_fnc_randomNum;
    _diff = 100 - _chance;
    
    if (_number >= _diff) then {
    
        _randItem = ( _itemArray select floor ( random ( count _itemArray ) ) );
        
        if (isClass (configFile >> "cfgMagazines" >> _randItem)) then {
        
            _weaponHolder = createVehicle [ "WeaponHolderSimulated", _x, [], 0, "CAN_COLLIDE" ]; 
            _weaponHolder addMagazineCargoGlobal [ _randItem, 2 ];
            
        } else {
        
            private ["_class"];
            _class = getText (configFile >> "cfgVehicles" >> _randItem >> "vehicleClass");
            
            if (_class == "Backpacks") then {
            
                _weaponHolder = createVehicle [ "WeaponHolderSimulated", _x, [], 0, "CAN_COLLIDE" ]; 
                _weaponHolder addBackPackCargoGlobal [ _randItem, 1 ];
                
            } else {
            
                _weaponHolder = createVehicle [_randItem, _x, [], 0, "CAN_COLLIDE"];    
                
            };
        };
        
        if (_debug) then {
        
            private ["_mrk"];
            
            _mrk = createMarker [ format ["Pos_M%1", random 1000], getPosATL _weaponHolder ]; 
            _mrk setMarkerShape "ICON"; 
            _mrk setMarkerType "mil_triangle"; 
            _mrk setMarkerColor "colorGreen"; 
            _mrk setMarkerSize [0.5,0.5]; 
            
        };
        
    };
    
} forEach _posArray;

if (_debug) then {player sideChat "!!! CREATING ITEMS DONE. !!!";};

nil  