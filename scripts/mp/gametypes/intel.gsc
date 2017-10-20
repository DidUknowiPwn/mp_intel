// ==========================================================
// Intel
//
// Component: intel.gsc
// Purpose: Intel gamemode game code
//
// Initial author: DidUknowiPwn
// Started: Octobe 19, 2017
// ==========================================================

// Base
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\math_shared;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\_util;
// T7ScriptSuite
#using scripts\m_shared\util_shared;

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

	//callback::on_connect( &on_player_connect );
	callback::on_spawned( &on_player_spawned );

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

function onSpawnPlayer( predictedSpawn )
{
	self.usingObj = undefined;

	if ( level.useStartSpawns && !level.inGracePeriod && !level.playerQueuedRespawn )
		level.useStartSpawns = false;

	spawning::onSpawnPlayer( predictedSpawn );
}

function on_player_spawned()
{
	// DEBUG
	/#
	self thread m_util::button_pressed( &UseButtonPressed, &generate_weights );
	#/
}

// ***************************
// Gamemode Code
// ***************************
function intel()
{

}


// ***************************
// Logic Code
// ***************************
function generate_weights()
{
	// it's decent but could use a little bit more spreading
	// we'll just need to randomize the weight values when being assigned
	const N_MAX_PERCENTAGE = 100.0;
	const N_MAX_SIZE = 3;

	n_per_object = N_MAX_PERCENTAGE / N_MAX_SIZE;
	n_total_perc = 0;
	n_rand_perc = undefined;

	a_weights = [];

	for( i = 0; i < N_MAX_SIZE - 1; i++ )
	{
		n_rand_perc = RandomInt( Int( n_per_object ) );
		n_total_perc += n_rand_perc;
		ARRAY_ADD( a_weights, n_rand_perc );
	}

	ARRAY_ADD( a_weights, Int( N_MAX_PERCENTAGE - n_total_perc ) );

	for( i = 0; i < a_weights.size; i++ )
		IPrintLn( "[" + i + 1 + "]: " + a_weights[i] );
}


// ***************************
// Spawn Code
// ***************************