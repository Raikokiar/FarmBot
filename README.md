# FarmBot
CC:Tweaked Farming turtle script

Farmbot is a farming turtle script that harvests at retangular perimeter and is able to compost seeds and bone meal crops 

# Setup Rules

## 1. Farm Requirements

* The farm must be retangular and have at least one row filled with any crops. Rows with gaps inside them for water source are ok for as long as there isn't any gaps on the outside borders
* There should be no obstructions above the farm perimeter. Things like saplings next to the farm can grow into a tree and cause malfunctions 
* **Ideally there should be a chunkloaders covering the whole farm so the turtle can work and the crops grow while players are away.**

For Maximizing timings of Farmbot, refer to the [Minecraft Wiki](https://minecraft.fandom.com/wiki/Tutorials/Crop_farming#Growth_and_harvesting) and the [Commands](https://github.com/Raikokiar/FarmBot#2-set-farmbotharvestinterval-interval-in-seconds) below to change the interval between harvests. Farmbot uses 31 minutes as default which is the fastest growth per seed under ideal conditions.


## 2. Turtle Deploy Site Requirements

_Turtle must be at a corner of your farm and it needs a container (chest, barrels, etc) behind it._

*PSA*: Farmbot will automatically disable composting routine if you haven't built Composting setup correctly beforehand. For enabling composting again, refer to the [Commands](https://github.com/Raikokiar/FarmBot#3-set-farmbotgrowandharvestfarmbotmaxaging-true-of-false-) segment

### Optional setups at the storing container corner:

* Fuel chests needs to be above the turtle so it can return when low on fuel

* To allow the turtle to compost you'll need to follow the setup below:

![Composting setup example](https://imgur.com/mJPnxCm.png)


## A full setup:

![Full setup](https://imgur.com/7gvUwKM.png)


# Commands

If you wish to change something then here are some commands to directly change the data of farmbot

### 1. `set farmbot false`

Regenerate data. Basically a reset command
_________________________

### 2. `set farmbot.harvestInterval [interval in seconds]`

Changes the waiting interval between harvest cycles.
________________________

### 3. `set farmbot.growAndHarvest/farmbot.maxAging [true of false] `

Disables or enables the max aging routine (responsible for discovering unknown crops mature age) or the grow and harvest routine. disable both and the turtle will not compost . If your turtle comes with both disabled, make the correct Composting setup and enabled them again
________________________

### 4. `set farmbot.sleepTimer [minutes] `

Changes the minutes remaining until the next harvest
________________________

### 5. `set farmbot.compostVegetables [true or false]`

Changes whether vegetables will be composted or not
