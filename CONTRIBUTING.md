# How to contribute

## Requirements
- git
- Java (Minimum 21)
- Internet connection

## Some things to note
### How can I tell where these patches came from?
In Vine, all patches are organized for easy reading.

From Vine: `0001-Config-Util.patch`

From Other Server: `0001-OtherServer-Config-Util.patch`

### Can I use patches made by Vine or fork Vine?
Yes, you can use patches from Vine on your fork or fork Vine yourself, but there are some restrictions.

1. Except as otherwise noted and for patches from other server software, you must distribute your patches under the GPL, rather than making a closed-source server software. (If you only use the software for yourself, you can ignore it)
2. The Vine name must be retained to let people know that the patch is from Vine. It is not required to leave a link to the Vine source code in the patch.

### Add commands in Vine
In Vine, only Bukkit-based command registration is provided for the time being. 
The specific registration method is shown in [this patch](patches/server/0011-Config-command.patch) as an example.

#### Requirements
1. Class must be under `one.tranic.vine.commands.module`
2. Must be written in `Kotlin`
3. If there is additional computation outside the command, split it into multiple patches.

### Add config in Vine
If you are adding a patch for Vine, and they have some configuration files:
1. Do not introduce additional configuration files. All new configuration files should be included in Vine Config.
2. Vine Config is divided into multiple patches. If you need to add new items, you need to modify the corresponding patches under Vine-API and Vine-Server respectively.
3. The configuration file class in Vine is automatically imported. If you create additional packages, you need to modify the Vine-Config-Util patch and add the full package name of the new package in the init scope of `one/tranic/vine/config/module/Module.kt` (no need to add class name qualification)
4. 

