<div align=center>
    <img src="assets/Vine.png" alt="">
    <h2>Vine 1.20.6 (Beta)</h2>
    <br /><br />
    <img src="https://img.shields.io/github/commit-activity/w/LevelTranic/Vine?style=flat-square" alt="">
    <img src="https://img.shields.io/github/downloads/LevelTranic/Vine/total?style=flat-square" alt="">
    <a href="https://tranic.one/downloads/vine"><img src="https://img.shields.io/github/release-date/LevelTranic/Vine?style=flat-square" alt=""></a>
    <a href="https://tranic.one/downloads/vine"><img src="https://img.shields.io/github/v/release/LevelTranic/Vine?style=flat-square" alt=""></a>
    <br /><br />
</div>

<p> 
<a href="https://tranic.one/software/vine">HomePage</a> | 
<a href="#download" >Download</a> | 
<a href="https://github.com/LevelTranic/Vine/issues">Issues</a> | 
<a href="https://docs.tranic.one/vine">Docs</a> |
<a href="https://discord.gg/dBbSbv2Vuz">Discord</a>
</p>

---
> **Upstream has started preparing 1.21.1, I will follow up when it compiles and runs normally.**
>
> ----
>
> What is certain is that Vine will not launch any proprietary API.
> You should use FoliaAPI or MultiLib to develop plugins.
>
> ShreddedPaper/Vine is completely different from Folia. Players'
> operations will still have a certain impact on other players,
> instead of the areas in Folia being completely unrelated
> (most of the time).
---

## What is Vine?
<p>Vine is a general multithreaded Minecraft server that is not specifically designed for one type of gameplay, as that would just cause more trouble. So, just do what you need to do and focus on optimizations, fixes, and features that don’t affect the game mechanics.</p>
<p>Vine was named after a friend of mine, which of course was nothing special, just because I didn't know what to name it.</p>
<br />

## Feature
- Sub-regional multi-threading introduced by ShreddedPaper can better withstand a large number of dense players.
- Builtin and the latest Kotlin dependency library.
- Various performance optimization.
- Support virtual threads
- Implement secure seeds to avoid cracking.
- Some interesting features, of course they are all turned off by default.
- Implemented SectorFile and Linear region formats to save a lot of storage space.
- Expanded options allow restoring more vanilla abilities.
- And some fixes from various places.
<br />

## Benchmark
I don't know

## Download
### Confirmable downloads
<p><a target="_blank" href="https://tranic.one/downloads/vine">Click To Download</a></p>

### Experimental Builds
<p><a target="_blank" href="https://github.com/LevelTranic/Vine/actions">Click To Download</a></p>

## Building

### Required
- Git
- Java (Minimum 21)
- Internet connection

### Steps
```Bash
git clone https://github.com/LevelTranic/Vine
cd Vine
./gradlew applyPatches && ./gradlew createMojmapBundlerJar
```