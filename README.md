# Auto Attacks Easily Visualized


[Image of an example AAEV Chart](https://i.imgur.com/r6K0wdm.png)


## How To
1. Download aaev.lua, aaev_settings.lua and the libraries folder. aaev.lua and the libraries folder can be found in the zip file under [Releases](https://github.com/darkewaffle/aaev/releases). You only need to download the settings file if you do not already have one - although it could change over time as new settings are supported.
2. Place them in Windower\addons\aaev.
3. Modify aaev_settings.lua to your liking.
4. "lua l aaev" in game to initialize the addon.
5. Go melee attack stuff and AAEV will chart the results.


## Description
So the idea behind this was I wanted to turn off all my auto attacks in the log but I didn't want to lose the information they provide. Namely am I missing, am I suddenly dealing noticeably less damage, am I dealing zero damage, etc. So essentially this monitors incoming packets for your own auto attacks, records the results and then turns them into a little chart while you're engaged with that enemy. Additionally the colors, size, appearance, number of bars and more can all be easily customized in a single settings file.

For the moment this is just a few days old so while it definitely works it hasn't been used or tested thoroughly yet. I also would suggest that if you use it you probably shouldn't set the number of bars too high - but otherwise feel free to take it for a spin and let me know what you think or if you encounter any problems.

Potential future ideas for it might be doing something with ranged attacks, differentiating between attacks that deal damage and attacks that heal, maybe identifying main-hand/off-hand hits so you could only display main if desired, maybe try to analyze multi attack %, who knows.