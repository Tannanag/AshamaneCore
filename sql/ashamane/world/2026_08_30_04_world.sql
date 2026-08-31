-- New Tinkertown: stop the Target Acquisition Devices (46012) spawning loaded.
--
-- Vehicle::Reset installs the accessory list the moment the device spawns, so
-- this row gave every one of them a Crazed Leper Gnome in seat 0 before it had
-- picked anything up. The script grabs a gnome that is already in the world.
DELETE FROM `vehicle_template_accessory` WHERE `entry`=46012;
