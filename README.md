# ExileMod-Vehicle-spawn-points

Script will provide the functionality of using specified objects to spawn vehicles with. If all positions available are full, a notification will be sent to the player.
Script utilizes extdb3 instead of extdb2, modify accordingly to extdb2.

Goal of script is to allow the following options:
* Allow for vehicles to spawn on designated points, via an object located on the map
* Still spawn vehicles (using the default Exile spawner), if no spawn point is detected
* Use a specified search radius, and a 'safe radius' around a spawn point

# Installation
Add ExileServer_system_trading_network_purchaseVehicleRequest.sqf to your mission overwrites folder and then add it to the `CfgExileCustomCode` class as required.

    IE:
    
    ``ExileServer_system_trading_network_purchaseVehicleRequest = "overwrites\extdb3\ExileServer_system_trading_network_purchaseVehicleRequest.sqf";``
