You can download/update this by running<br/>
`wget run https://raw.githubusercontent.com/HappySunChild/Plethora-Shrug-Client/main/downloader.lua`

### Required Modules
- Chat Recorder
- Overlay Glasses
- Entity Sensor

### Optional/Interchangable Modules
- Kinetic Augment
- Block Scanner
- Frickin' Laser Beam

### Shrug Proxy Server
A Shrug Proxy Server can be set up to allow for remote commands to extra modules.<br/>

Server startup file download command:<br/>
`wget https://raw.githubusercontent.com/HappySunChild/Plethora-Shrug-Client/main/src/server.lua startup.lua`

### Commands
There are currently *6* different command handlers available, they are:
- `.scan` (Requires Block Scanner)
- `.fly` (Requires Kinetic Augment)
- `.laser` (Requires Frickin' Laser Beam)
- `.killaura` (Requires Frickin' Laser Beam)
- `.remote` (Requires Shrug Proxy Server)
- `.settings`

Typing any of these into chat will give a list of commands you can run with them, assuming you have the module they require.
