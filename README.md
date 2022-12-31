# Grinch Simulator

The Grinch has no-clipped out of reality and into a desolate city! Help him steal all their presents and avoid being caught by Santa.

## Inspiration 🤔

Grinch Simulator's art style was inspired by classic 80s games. I actually used the NES's colour palette to draw all the textures. Gameplay wise, I took inspiration from the popular genre of maze horror games like [Labyrinthine](https://store.steampowered.com/app/1302240/Labyrinthine/), and [The Backrooms](https://store.steampowered.com/app/1111210/The_Backrooms_Game_FREE_Edition/). These games use the uncanny feeling of desolation and loneliness among a familiar environment to build suspense. I also heavily relied on music and sound effects, which I took from open source projects, in order to create a thematic environment.

## What it does 🎁

In Grinch Simulator, the player plays as the Grinch who finds themselves in the middle of a desolate town on Christmas Eve. The player must navigate the complex maze while stealing any presents found along the way. But there is a catch! Santa is also on the loose and he is not too excited to see the Grinch's plot to ruin Christmas. The player must must avoid running into Santa at all costs and make use of their stamina to sprint away when he gets too close. But stamina will quickly deplete, and it takes a long time to regenerate.

## How I built it ⚡

I created this game with the [Zig programming language](https://ziglang.org/) and the [Raylib graphics library](https://www.raylib.com/) using [emscripten](https://emscripten.org/) to compile to [web assembly](https://webassembly.org/).

This project was created based on [this zig-raylib examples repo](https://github.com/ryupold/examples-raylib.zig). I had to do major tweaking to get it to compile. Several random Raylib source files were giving errors and connecting my emscripten SDK was really finicky. Overall, I was surprised with the quality of documentation available for such niche technologies.

## Challenges I ran into 👨🏻‍💻

I ran into many challenged while creating Grinch Simulator. One major challenge occurred when developing the system which textures the buildings and other 2.5D sprites. The graphics api Raylib provides is extremely low level and I had several issues with version discrepancies between the documentation and the version I was using. In the end, through a lot of trial and error, I managed to get textures rendering in a slightly incorrect manner which I was able to manually correct on a per case basis.

## Accomplishments that I'm proud of ⭐

I'm proud of my implementation of the lighting system. Last year, during the Holiday Game Jam 2021, I implemented a similar lightning system in [my team's submission](https://mcptjam2021.netlify.app). However, last year I attempted to implement it in a [glsl shader](https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_on_the_web/GLSL_Shaders) and my inexperience working with glsl, as well as my improper use case, lead to the final product being slow, imprecise and not particularly all too amazing looking. This year I used a much simpler implementation that runs entirely on the CPU. I was able to make many optimization this time around which has lead to an infinitely better performance at no cost to quality. 

## What I learned 📔

Throughout the course of this jam, I became significantly more adept working with Zig. I believe this low level programming experience will translate to other programming languages of similar caliber, such as C or Rust. At the beginning of the jam, I was overly hesitant to use dynamic memory allocation for fear that it would lead to memory leaks. By the end of the jam, I had learned how to allocate memory and free it properly and was making much more use of it.

## What's next for Grinch Simulator 📆

I think that I would like to expand this game by drawing more texture variations. Right now there are only 3 textures wall textures between every building. I could also make use of tinting, rotating, and mirroring textures to increase the diversity. I also think that in the future I would like to further develop Santa's AI, as currently the path finding algorithm is far from perfect. I would like the system to be more dynamic overall.
