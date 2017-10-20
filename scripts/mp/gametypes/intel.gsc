// ==========================================================
// Intel
//
// Component: intel.gsc
// Purpose: Intel gamemode game code
//
// Initial author: DidUknowiPwn
// Started: Octobe 19, 2017
// ==========================================================

#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\gametypes\_dogtags;
#using scripts\mp\_teamops;
#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;

#precache( "string", "MOD_OBJECTIVES_TDM" );
#precache( "string", "MOD_OBJECTIVES_TDM_SCORE" );
#precache( "string", "MOD_OBJECTIVES_TDM_HINT" );

function main()
{
	globallogic::init();

	util::registerRoundSwitch( 0, 9 );
	util::registerTimeLimit( 0, 1440 );
	util::registerScoreLimit( 0, 50000 );
	util::registerRoundLimit( 0, 10 );
	util::registerRoundWinLimit( 0, 10 );
	util::registerNumLives( 0, 100 );

	globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = &onStartGameType;
	level.onSpawnPlayer = &onSpawnPlayer;

	gameobjects::register_allowed_gameobject( level.gameType );

	globallogic_audio::set_leader_gametype_dialog ( undefined, undefined, "gameBoost", "gameBoost" );

	// Sets the scoreboard columns and determines with data is sent across the network
	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "kdratio", "assists" );
}

function onStartGameType()
{
	level.useStartSpawns = true;

	if ( !isdefined( game["switchedsides"] ) )
	{
		game["switchedsides"] = false;
	}

	SetClientNameMode("auto_change");

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	util::setObjectiveText( game["attackers"], &"MOD_OBJECTIVES_INTEL" );
	util::setObjectiveText( game["defenders"], &"MOD_OBJECTIVES_INTEL" );

	util::setObjectiveScoreText( game["attackers"], &"MOD_OBJECTIVES_INTEL_SCORE" );
	util::setObjectiveScoreText( game["defenders"], &"MOD_OBJECTIVES_INTEL_SCORE" );

	util::setObjectiveHintText( game["attackers"], &"MOD_OBJECTIVES_INTEL_HINT" );
	util::setObjectiveHintText( game["defenders"], &"MOD_OBJECTIVES_INTEL_HINT" );

	// Set up Spawn points
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	spawnlogic::place_spawn_points( "mp_escort_spawn_attacker_start" );
	spawnlogic::place_spawn_points( "mp_escort_spawn_defender_start" );

	level.spawn_start = [];
	level.spawn_start["allies"] = spawnlogic::get_spawnpoint_array( "mp_escort_spawn_attacker_start" );
	level.spawn_start["axis"] = spawnlogic::get_spawnpoint_array( "mp_escort_spawn_defender_start" );

	spawnlogic::add_spawn_points( "allies", "mp_escort_spawn_attacker" );
	spawnlogic::add_spawn_points( "axis", "mp_escort_spawn_defender" );

	spawning::updateAllSpawnPoints();

	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );

	spawnpoint = spawnlogic::get_random_intermission_point();
	SetDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );
}

function onSpawnPlayer(predictedSpawn)
{
	self.usingObj = undefined;

	if ( level.useStartSpawns && !level.inGracePeriod && !level.playerQueuedRespawn )
	{
		level.useStartSpawns = false;
	}

	spawning::onSpawnPlayer(predictedSpawn);
}