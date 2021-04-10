# sig_quart_bot
Welcome to my discord bot!

## Installation
1. Install Discordia, you can find it [here](https://github.com/SinisterRectus/Discordia). 
2. Clone this repository. **Note: I have modified 2 files in the voice lib in Discordia, if you want the music module to work then please replace the original files with the files in ``deps/discordia/libs/voice``**
3. Download a static (exe) build of youtube-dl, you can find it [here](https://github.com/ytdl-org/youtube-dl/releases).
4. Place the youtube-dl.exe in your bot directory or somewhere else however you will need to add the program path to your system environment variables.
5. Repeat steps 3 and 4 for FFmpeg which can be found [here](https://github.com/BtbN/FFmpeg-Builds/releases).
6. Repeat steps 3 and 4 for both of the required Dynamic Link Libraries ``sodium`` and ``opus`` which can be found [here](https://github.com/SinisterRectus/Discordia/tree/master/bin).
7. Repeat steps 3 and 4 for SQLite, the instructions can be found [here](https://github.com/SinisterRectus/lit-sqlite3).
8. Install coro-spawn by executing ``lit install creationix/coro-spawn``.
9. Start the bot using ``luvit b.lua``

*Optional :*  Repeat steps 3 and 4 for Aria2c which can be found [here](https://aria2.github.io/).

## Problems
Due to lack of time, my ability to test modules fully has been hindered therefore if you encounter a problem please create an issue or even better, create a PR to fix it.

- The bot is not designed for multiple guilds, in fact, some modules will cause problems in multiple guilds. For example the music queue is not guild specific.

## Modifications
I really wanted to avoid modification of the original Discordia library however I couldn't find a reliable alternative for certain features I wanted to implement, particularly in the ``music`` module.

- Callback when FFmpeg actually starts playing.
- Replacing or passing additional arguments to FFmpeg. This allows for "seeking" audio to a particular point.

If anyone has a solution which avoids modification of Discordia but still provides the same functionality then please make a PR.


## Documentation
I don't really plan on documenting my bot because it is purely for **reference**.