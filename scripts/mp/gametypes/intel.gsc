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
#using scripts\shared\popups_shared;
#using scripts\shared\sound_shared;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\teams\_teams;
#using scripts\mp\_util;
// T7ScriptSuite
#using scripts\m_shared\util_shared;

#insert scripts\shared\shared.gsh;

#precache( "objective", "allies_base" );
#precache( "objective", "axis_base" );
#precache( "objective", "hardpoint" );

#define MODEL_BASE "thing"
#define MODEL_INTEL "thing2"

//#precache( "xmodel", MODEL_BASE );
//#precache( "xmodel", MODEL_INTEL );

#precache( "string", "MOD_OBJECTIVES_INTEL" );
#precache( "string", "MOD_OBJECTIVES_INTEL_SCORE" );
#precache( "string", "MOD_OBJECTIVES_INTEL_HINT" );
#precache( "string", "MOD_RETRIEVED_INTEL" );
#precache( "string", "MOD_DROPPED_INTEL" );

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

	globallogic_audio::set_leader_gametype_dialog( undefined, undefined, "gameBoost", "gameBoost" );

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
	self thread m_util::spawn_bot_button();
	self thread m_util::button_pressed( &ActionSlotOneButtonPressed, &generate_weights );
	self thread m_util::button_pressed( &ActionSlotTwoButtonPressed, &spawn_intel );
	self thread m_util::button_pressed( &ActionSlotThreeButtonPressed, &spawn_base );
	#/
}

// ***************************
// Gamemode Code
// ***************************

function intel()
{
	level.bases = []; // teams: allies, axis
	level.intels = []; // array of intels
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
		IPrintLn( "[" + i + "]: " + a_weights[i] );
}


// ***************************
// Spawn Code
// ***************************
// self = level.bases
function spawn_base( spot )
{
	// TODO
	if ( !isdefined( spot ) )
		spot = self;
	// model
	model = Spawn( "script_model", spot.origin );
	model SetModel( teams::get_flag_model( "allies" ) );//model SetModel( MODEL_INTEL );
	visuals = Array( model );

	// trigger
	trigger = Spawn( "trigger_radius_use", spot.origin + (0,0,32), 0, 32, 32 );
	trigger SetCursorHint( "HINT_NOICON" );
	//trigger SetHintString( "Press &&1 to upload Intel" );
	trigger TriggerIgnoreTeam();
	trigger UseTriggerRequireLookAt();

	// gameobject - carry
	obj = gameobjects::create_use_object( "neutral", trigger, visuals, (0,0,0), &"hardpoint" );
	obj gameobjects::set_use_time( 5 );
	obj gameobjects::set_use_text( "Uploading Intel" );
	obj gameobjects::set_use_hint_text( "Press &&1 to upload Intel" );
	obj gameobjects::set_team_use_time( "friendly", 5 );
	obj gameobjects::set_team_use_time( "enemy", 10 );
	obj gameobjects::allow_use( "any" );
	obj gameobjects::set_visible_team( "any" );

	obj.onBeginUse = &on_use_base;
	obj.useWeapon = GetWeapon( "briefcase_bomb_defuse" );

	return obj;
}
// self = gameobject
function on_use_base( player )
{
	IPrintLn( player.name + " " + player.team );
}
// self = level.intels
function spawn_intel( spot )
{
	// TODO
	if ( !isdefined( spot ) )
		spot = self;
	// model
	model = Spawn( "script_model", spot.origin );
	model SetModel( teams::get_flag_model( "allies" ) );//model SetModel( MODEL_INTEL );
	visuals = Array( model );

	// trigger
	trigger = Spawn( "trigger_radius_use", spot.origin + (0,0,32), 0, 32, 32 );
	trigger SetCursorHint( "HINT_NOICON" );
	trigger SetHintString( "Press &&1 to gather intel");
	trigger TriggerIgnoreTeam();
	trigger UseTriggerRequireLookAt();

	// gameobject - carry
	obj = gameobjects::create_carry_object( "neutral", trigger, visuals, (0,0,0), &"hardpoint" );
	obj gameobjects::set_team_use_time( "friendly", 0 );
	obj gameobjects::set_team_use_time( "enemy", 0 );
	obj gameobjects::set_visible_team( "any" );
	obj gameobjects::allow_carry( "any" );

	obj.onPickup = &on_pickup_intel;
	obj.onDrop = &on_drop_intel;
	obj.allowWeapons = true;
	obj.objIDPingFriendly = true;

	return obj;
}
// self = gameobject
function on_pickup_intel( player )
{
	team = self gameobjects::get_owner_team();
	otherTeam = util::getOtherTeam( team );

	globallogic_audio::play_2d_on_team( "mpl_flagget_sting_friend", otherTeam );
	globallogic_audio::play_2d_on_team( "mpl_flagget_sting_enemy", team );

	level thread popups::DisplayTeamMessageToAll( &"MOD_RETRIEVED_INTEL", player );
}
// self = gameobject
function on_drop_intel( player )
{
	team = self gameobjects::get_owner_team();
	otherTeam = util::getOtherTeam( team );

	globallogic_audio::play_2d_on_team( "mpl_flagdrop_sting_friend", otherTeam );
	globallogic_audio::play_2d_on_team( "mpl_flagdrop_sting_enemy", team );

	thread sound::play_on_players( "mp_war_objective_lost", otherTeam );

	level thread popups::DisplayTeamMessageToAll( &"MOD_DROPPED_INTEL", player );
}
//globallogic_audio::play_2d_on_team( "mpl_flagcapture_sting_enemy", enemyTeam );
//globallogic_audio::play_2d_on_team( "mpl_flagcapture_sting_friend", team );