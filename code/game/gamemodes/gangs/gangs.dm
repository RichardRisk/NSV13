//gang.dm
//Gang War Game Mode
GLOBAL_LIST_INIT(possible_gangs, subtypesof(/datum/team/gang))
GLOBAL_LIST_EMPTY(gangs)
/datum/game_mode/gang
	name = "gang war"
	config_tag = "gang"
	role_preference = /datum/role_preference/antagonist/gangster
	antag_datum = /datum/antagonist/gang
	restricted_jobs = list(JOB_NAME_SECURITYOFFICER, JOB_NAME_WARDEN, JOB_NAME_DETECTIVE, JOB_NAME_AI, JOB_NAME_CYBORG,JOB_NAME_CAPTAIN, JOB_NAME_HEADOFPERSONNEL, JOB_NAME_HEADOFSECURITY)
	required_players = 15 //NSV13 - down from 30
	required_enemies = 1 //NSV13 - down from 2
	recommended_enemies = 2 //NSV13 - down from 3

	announce_span = "danger"
	announce_text = "A violent turf war has erupted on the station!\n\
	<span class='danger'>Gangsters</span>: Spread influence and expand the territory of your gang.\n\
	<span class='notice'>Crew</span>: Spread awareness and prevent your coworkers from killing eachother in turf wars."

	title_icon = "gang"

	var/list/datum/mind/gangboss_candidates = list()

/datum/game_mode/gang/pre_setup()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += JOB_NAME_ASSISTANT

	//Spawn more bosses depending on server population
	var/gangs_to_create = 2
	if(prob(num_players()) && num_players() > 2*required_players)
		gangs_to_create++
	if(prob(num_players()) && num_players() > 3*required_players)
		gangs_to_create++
	gangs_to_create = min(gangs_to_create, GLOB.possible_gangs.len)

	for(var/i in 1 to gangs_to_create)
		if(!antag_candidates.len)
			break

		//Now assign a boss for the gang
		var/datum/mind/boss = pick_n_take(antag_candidates)
		antag_candidates -= boss
		gangboss_candidates += boss
		boss.restricted_roles = restricted_jobs

	if(gangboss_candidates.len < 1) //Need at least one gangs
		return

	return TRUE

/datum/game_mode/gang/post_setup()
	set waitfor = FALSE
	..()
	for(var/i in gangboss_candidates)
		var/datum/mind/M = i
		var/datum/antagonist/gang/boss/B = new()
		M.add_antag_datum(B)
		B.equip_gang()

///////////////////////////////////////////////////
//Deals with checking if player is a gangster    //
///////////////////////////////////////////////////
/proc/is_gangster(mob/M)
	return M?.mind?.has_antag_datum(/datum/antagonist/gang)

/proc/is_gang_boss(mob/M)
	return M?.mind?.has_antag_datum(/datum/antagonist/gang/boss)

/datum/game_mode/gang/set_round_result()
	..()
	var/datum/team/gang/winner
	var/winner_territories = 0
	for(var/datum/team/gang/G in GLOB.gangs)
		var/compare_territories = LAZYLEN(G.territories)
		if (!winner || compare_territories > winner_territories || (compare_territories == winner_territories && G.victory_points > winner.victory_points))
			winner = G
			winner_territories = LAZYLEN(winner.territories)

	if (winner)
		winner.winner = TRUE	//chicken dinner

/datum/game_mode/gang/generate_credit_text()
	var/list/round_credits = list()
	var/len_before_addition

	for(var/datum/team/gang/G in GLOB.gangs)
		round_credits += "<center><h1>[G.name] Gang:</h1>"
		len_before_addition = round_credits.len
		for(var/datum/mind/boss in G.leaders)
			round_credits += "<center><h2>[boss.name] jako lider gangu [G.name]</h2>"
		for(var/datum/mind/gangster in (G.members - G.leaders))
			round_credits += "<center><h2>[gangster.name] jako gangster [G.name]</h2>"
		if(len_before_addition == round_credits.len)
			round_credits += list("<center><h2>The [G.name] Gang został zmieciony!</h2>", "<center><h2>Konkurencja była zbyt silna!</h2>")
		round_credits += "<br>"

	round_credits += ..()
	return round_credits
