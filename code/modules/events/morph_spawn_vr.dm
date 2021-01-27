/datum/event/morph_spawn
	startWhen = 1
	endWhen = 30

/datum/event/morph_spawn/start()

	var/obj/effect/landmark/spawnspot = null
	var/list/possibleSpawnspots = list()
	for(var/obj/effect/landmark/newSpawnspot in landmarks_list)
		if(newSpawnspot.name == "morphspawn")
			possibleSpawnspots += newSpawnspot
	if(possibleSpawnspots.len)
		spawnspot = pick(possibleSpawnspots)
	else
		kill()		// To prevent fake announcements
		return

	if(!spawnspot)
		kill()		// To prevent fake announcements
		return

<<<<<<< HEAD
	var/datum/ghost_query/Q = new /datum/ghost_query/morph()
	var/list/winner = Q.query()

	if(winner.len)
		var/mob/living/simple_mob/vore/hostile/morph/newMorph = new /mob/living/simple_mob/vore/hostile/morph(get_turf(spawnspot))
		var/mob/observer/dead/D = winner[1]
		if(D.mind)
			D.mind.transfer_to(newMorph)
		to_chat(D, "<span class='notice'>You are a <b>Morph</b>, somehow having gotten aboard the station in your wandering. \
		You are wary of environment around you, but your primal hunger still calls for you to find prey. Seek a convincing disguise, \
		using your amorphous form to traverse vents to find and consume weak prey.</span>")
		to_chat(D, "<span class='notice'>You can use shift + click on objects to disguise yourself as them, but your strikes are nearly useless when you are disguised. \
		You can undisguise yourself by shift + clicking yourself, but disguise being switched, or turned on and off has a short cooldown. You can also ventcrawl, \
		by using alt + click on the vent or scrubber.</span>")
		newMorph.ckey = D.ckey
		newMorph.visible_message("<span class='warning'>A morph appears to crawl out of somewhere.</span>")
	else
		kill()		// To prevent fake announcements
		return


/datum/event/morph_spawn/announce()
	if(prob(announceProb))
		command_announcement.Announce("Unknown entitity detected boarding [station_name()]. Exercise extra caution.", "Lifesign Alert", new_sound = 'sound/AI/aliens.ogg')

//YW Addition: Adding named landmark for events
/obj/effect/landmark/event_spawn/morphspawn
	name = "morphspawn"
||||||| parent of 6524b38e17... Merge pull request #9615 from Heroman3003/ghostpod-conversion
	var/datum/ghost_query/Q = new /datum/ghost_query/morph()
	var/list/winner = Q.query()

	if(winner.len)
		var/mob/living/simple_mob/vore/hostile/morph/newMorph = new /mob/living/simple_mob/vore/hostile/morph(get_turf(spawnspot))
		var/mob/observer/dead/D = winner[1]
		if(D.mind)
			D.mind.transfer_to(newMorph)
		to_chat(D, "<span class='notice'>You are a <b>Morph</b>, somehow having gotten aboard the station in your wandering. \
		You are wary of environment around you, but your primal hunger still calls for you to find prey. Seek a convincing disguise, \
		using your amorphous form to traverse vents to find and consume weak prey.</span>")
		to_chat(D, "<span class='notice'>You can use shift + click on objects to disguise yourself as them, but your strikes are nearly useless when you are disguised. \
		You can undisguise yourself by shift + clicking yourself, but disguise being switched, or turned on and off has a short cooldown. You can also ventcrawl, \
		by using alt + click on the vent or scrubber.</span>")
		newMorph.ckey = D.ckey
		newMorph.visible_message("<span class='warning'>A morph appears to crawl out of somewhere.</span>")
	else
		kill()		// To prevent fake announcements
		return


/datum/event/morph_spawn/announce()
	if(prob(announceProb))
		command_announcement.Announce("Unknown entitity detected boarding [station_name()]. Exercise extra caution.", "Lifesign Alert", new_sound = 'sound/AI/aliens.ogg')
=======
	new /obj/structure/ghost_pod/ghost_activated/morphspawn(get_turf(spawnspot))
>>>>>>> 6524b38e17... Merge pull request #9615 from Heroman3003/ghostpod-conversion
