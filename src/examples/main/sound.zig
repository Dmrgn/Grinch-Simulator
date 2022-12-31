const std = @import("std");
const raylib = @import("../../raylib/raylib.zig");

const Music = raylib.Music;
const Sound = raylib.Sound;

pub var music: Music = undefined;
pub var chaseMusic: Music = undefined;

pub var heartBeat: Sound = undefined;
pub var near: Sound = undefined;
pub var scream: Sound = undefined;
pub var laughs: [3]Sound = undefined;

pub fn loadSounds() void {
    raylib.InitAudioDevice(); 
    // load music
    music = raylib.LoadMusicStream("assets/ambience.wav");
    chaseMusic = raylib.LoadMusicStream("assets/chase.mp3");
    // load sound effects
    heartBeat = raylib.LoadSound("assets/heartbeat.mp3");
    near = raylib.LoadSound("assets/near.mp3");
    scream = raylib.LoadSound("assets/scream.mp3");
    comptime var i = 1;
    inline while (i <= laughs.len) : (i+=1) {
        laughs[i-1] = raylib.LoadSound("assets/laugh-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".mp3");
    }
}

pub fn playHeartBeat() void {
    raylib.PlaySoundMulti(heartBeat);
}

fn loopMusicStream(stream: *Music) void {
    const streamTimePlayed: f32 = raylib.GetMusicTimePlayed(stream.*)/raylib.GetMusicTimeLength(stream.*);
    if (streamTimePlayed > 1.0) {
        raylib.StopMusicStream(stream.*);
        raylib.PlayMusicStream(stream.*);
    }
}

pub fn loopMusic() void {
    raylib.UpdateMusicStream(music);
    raylib.UpdateMusicStream(chaseMusic);
    loopMusicStream(&music);
    loopMusicStream(&chaseMusic);
}