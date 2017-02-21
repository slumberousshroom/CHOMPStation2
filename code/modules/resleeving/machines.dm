////////////////////////////////
//// Machines required for body printing
//// and decanting into bodies
////////////////////////////////

/////// Grower Pod ///////
/obj/machinery/clonepod/transhuman
	name = "grower pod"
	circuit = /obj/item/weapon/circuitboard/transhuman_clonepod

/obj/machinery/clonepod/transhuman/growclone(var/datum/transhuman/body_record/current_project)
	var/datum/dna2/record/R = current_project.mydna
	if(mess || attempting)
		return 0

	attempting = 1 //One at a time!!
	locked = 1

	eject_wait = 1
	spawn(30)
		eject_wait = 0

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src, R.dna.species)
	if(current_project.locked)
		H.resleeve_lock = current_project.ckey

	//Fix the external organs
	for(var/part in current_project.limb_data)

		var/status = current_project.limb_data[part]
		if(status == null) continue //Species doesn't have limb? Child of amputated limb?

		var/obj/item/organ/external/O = H.organs_by_name[part]
		if(!O) continue //Not an organ. Perhaps another amputation removed it already.

		if(status == 1) //Normal limbs
			continue
		else if(status == 0) //Missing limbs
			O.remove_rejuv()
		else if(status) //Anything else is a manufacturer
			O.remove_rejuv() //Don't robotize them, leave them removed so robotics can attach a part.

	//Look, this machine can do this because [reasons] okay?!
	for(var/part in current_project.organ_data)

		var/status = current_project.organ_data[part]
		if(status == null) continue //Species doesn't have organ? Child of missing part?

		var/obj/item/organ/I = H.internal_organs_by_name[name]
		if(!I) continue//Not an organ. Perhaps external conversion changed it already?

		if(part == O_EYES && status > 0) //But not eyes. The only non-essential internal organ.
			qdel(I)
			continue

		if(status == 0) //Normal organ
			continue
		else if(status == 1) //Assisted organ
			I.mechassist()
		else if(status == 2) //Mechanical organ
			I.robotize()
		else if(status == 3) //Digital organ
			I.digitize()

	occupant = H

	if(!R.dna.real_name)
		R.dna.real_name = "clone ([rand(0,999)])"
	H.real_name = R.dna.real_name

	H.adjustCloneLoss(150)
	H.Paralyse(4)
	H.updatehealth()

	if(!R.dna)
		H.dna = new /datum/dna()
		H.dna.real_name = H.real_name
	else
		H.dna = R.dna
	H.UpdateAppearance()
	H.sync_organ_dna()
	if(heal_level < 60)
		randmutb(H)
		H.dna.UpdateSE()
		H.dna.UpdateUI()

	H.set_cloned_appearance()
	update_icon()
	H.ooc_notes = current_project.body_oocnotes
	H.flavor_texts = R.flavor.Copy()
	H.size_multiplier = current_project.sizemult
	H.suiciding = 0
	attempting = 0
	return 1

/obj/machinery/clonepod/transhuman/process()
	if(stat & NOPOWER)
		if(occupant)
			locked = 0
			go_out()
		return

	if((occupant) && (occupant.loc == src))
		if(occupant.stat == DEAD)
			locked = 0
			go_out()
			connected_message("Clone Rejected: Deceased.")
			return

		else if(occupant.health < heal_level && occupant.getCloneLoss() > 0)

			 //Slowly get that clone healed and finished.
			occupant.adjustCloneLoss(-2 * heal_rate)

			//Premature clones may have brain damage.
			occupant.adjustBrainLoss(-(ceil(0.5*heal_rate)))

			//So clones don't die of oxyloss in a running pod.
			if(occupant.reagents.get_reagent_amount("inaprovaline") < 30)
				occupant.reagents.add_reagent("inaprovaline", 60)

			//Also heal some oxyloss ourselves because inaprovaline is so bad at preventing it!!
			occupant.adjustOxyLoss(-4)

			use_power(7500) //This might need tweaking.
			return

		else if((occupant.health >= heal_level) && (!eject_wait))
			playsound(src.loc, 'sound/machines/ding.ogg', 50, 1)
			audible_message("\The [src] signals that the growing process is complete.")
			connected_message("Growing Process Complete.")
			locked = 0
			go_out()
			return

	else if((!occupant) || (occupant.loc != src))
		occupant = null
		if(locked)
			locked = 0
		return

	return

//Synthetic version
/obj/machinery/transhuman/synthprinter
	name = "SynthFab 3000"
	desc = "A rapid fabricator for synthetic bodies."
	icon = 'icons/obj/machines/synthpod.dmi'
	icon_state = "pod_0"
	circuit = /obj/item/weapon/circuitboard/transhuman_synthprinter
	density = 1
	anchored = 1

	var/list/stored_material =  list(DEFAULT_WALL_MATERIAL = 30000, "glass" = 30000)
	var/connected      //What console it's done up with
	var/busy = 0       //Busy cloning
	var/body_cost = 15000  //Cost of a cloned body (metal and glass ea.)
	var/datum/transhuman/body_record/current_project
	var/broken = 0

/obj/machinery/transhuman/synthprinter/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/stock_parts/matter_bin(src)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(src)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	RefreshParts()
	update_icon()

/obj/machinery/transhuman/synthprinter/process()
	if(stat & NOPOWER)
		if(busy)
			busy = 0
			current_project = null
		update_icon()
		return

	if(busy > 0 && busy <= 95)
		busy += 5

	if(busy >= 100)
		make_body()

	return

/obj/machinery/transhuman/synthprinter/proc/print(var/datum/transhuman/body_record/BR)
	if(!istype(BR) || busy)
		return 0

	if(stored_material[DEFAULT_WALL_MATERIAL] < body_cost || stored_material["glass"] < body_cost)
		return 0

	current_project = BR
	busy = 5
	update_icon()

	return 1

/obj/machinery/transhuman/synthprinter/proc/make_body()
	if(!current_project)
		busy = 0
		update_icon()
		return

	//Blep us a new blank body to robotize (based on their original species choice).
	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src, current_project.mydna.dna.species)
	H.name = current_project.mydna.dna.real_name
	H.real_name = H.name
	if(current_project.locked)
		H.resleeve_lock = current_project.ckey

	H.ooc_notes = current_project.body_oocnotes
	H.flavor_texts = current_project.mydna.flavor.Copy()

	//First the external organs
	for(var/part in current_project.limb_data)

		var/status = current_project.limb_data[part]
		if(status == null) continue //Species doesn't have limb? Child of amputated limb?

		var/obj/item/organ/external/O = H.organs_by_name[part]
		if(!O) continue //Not an organ. Perhaps another amputation removed it already.

		if(status == 1) //Normal limbs
			continue
		else if(status == 0) //Missing limbs
			O.remove_rejuv()
		else if(status) //Anything else is a manufacturer
			O.robotize(status)

	//Then the internal organs
	for(var/part in current_project.organ_data)

		var/status = current_project.organ_data[part]
		if(status == null) continue //Species doesn't have organ? Child of missing part?

		var/obj/item/organ/I = H.internal_organs_by_name[name]
		if(!I) continue//Not an organ. Perhaps external conversion changed it already?

		if(status == 0) //Normal organ
			continue
		else if(status == 1) //Assisted organ
			I.mechassist()
		else if(status == 2) //Mechanical organ
			I.robotize()
		else if(status == 3) //Digital organ
			I.digitize()

	H.adjustBruteLoss(20)
	H.adjustFireLoss(20)

	H.size_multiplier = current_project.sizemult

	//Cha-ching.
	stored_material[DEFAULT_WALL_MATERIAL] -= body_cost
	stored_material["glass"] -= body_cost

	//Plonk them here.
	H.loc = get_turf(src)

	//Reset stuff.
	busy = 0
	update_icon()

/obj/machinery/transhuman/synthprinter/attack_hand(mob/user as mob)
	if((busy == 0) || (stat & NOPOWER))
		return
	user << "Current print cycle is [busy]% complete."
	return

/obj/machinery/transhuman/synthprinter/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)
	if(busy)
		user << "<span class='notice'>\The [src] is busy. Please wait for completion of previous operation.</span>"
		return
	if(default_deconstruction_screwdriver(user, W))
		return
	if(default_deconstruction_crowbar(user, W))
		return
	if(default_part_replacement(user, W))
		return
	if(panel_open)
		user << "<span class='notice'>You can't load \the [src] while it's opened.</span>"
		return
	if(!istype(W, /obj/item/stack/material))
		user << "<span class='notice'>You cannot insert this item into \the [src]!</span>"
		return

	var/obj/item/stack/material/S = W
	if(!(S.material.name in stored_material))
		user << "<span class='warning'>\the [src] doesn't accept [S.material]!</span>"
		return

	var/amnt = S.perunit
	var/max_res_amount = 30000
	if(stored_material[S.material.name] + amnt <= max_res_amount)
		if(S && S.amount >= 1)
			var/count = 0
			while(stored_material[S.material.name] + amnt <= max_res_amount && S.amount >= 1)
				stored_material[S.material.name] += amnt
				S.use(1)
				count++
			user << "You insert [count] [S.name] into \the [src]."
	else
		user << "\the [src] cannot hold more [S.name]."

	updateUsrDialog()
	return

/obj/machinery/transhuman/synthprinter/update_icon()
	..()
	icon_state = "pod_0"
	if(busy && !(stat & NOPOWER))
		icon_state = "pod_1"
	else if(broken)
		icon_state = "pod_g"

/////// Resleever Pod ///////
/obj/machinery/transhuman/resleever
	name = "resleeving pod"
	desc = "Used to combine mind and body into one unit."
	icon = 'icons/obj/machines/implantchair.dmi'
	icon_state = "implantchair"
	circuit = /obj/item/weapon/circuitboard/transhuman_resleever
	density = 1
	opacity = 0
	anchored = 1

	var/mob/living/carbon/human/occupant = null
	var/connected = null

/obj/machinery/transhuman/resleever/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(src)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(src)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new /obj/item/weapon/stock_parts/console_screen(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	RefreshParts()
	update_icon()

/obj/machinery/transhuman/resleever/attack_hand(mob/user as mob)
	user.set_machine(src)
	var/health_text = ""
	var/mind_text = ""
	if(src.occupant)
		if(src.occupant.stat >= DEAD)
			health_text = "<FONT color=red>DEAD</FONT>"
		else if(src.occupant.health < 0)
			health_text = "<FONT color=red>[round(src.occupant.health,0.1)]</FONT>"
		else
			health_text = "[round(src.occupant.health,0.1)]"

		if(src.occupant.client)
			mind_text = "Mind present"
		else
			mind_text = "Mind absent"

	var/dat ="<B>Resleever Status</B><BR>"
	dat +="<B>Current occupant:</B> [src.occupant ? "<BR>Name: [src.occupant]<BR>Health: [health_text]<BR>" : "<FONT color=red>None</FONT>"]<BR>"
	dat +="<B>Mind status:</B> [mind_text]<BR>"
	user.set_machine(src)
	user << browse(dat, "window=resleever")
	onclose(user, "resleever")

/obj/machinery/transhuman/resleever/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)
	if(default_deconstruction_screwdriver(user, W))
		return
	if(default_deconstruction_crowbar(user, W))
		return
	if(default_part_replacement(user, W))
		return
	if(istype(W, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = W
		if(!ismob(G.affecting))
			return
		for(var/mob/living/carbon/slime/M in range(1, G.affecting))
			if(M.Victim == G.affecting)
				usr << "[G.affecting:name] will not fit into the [src.name] because they have a slime latched onto their head."
				return
		var/mob/M = G.affecting
		if(put_mob(M))
			qdel(G)
	src.updateUsrDialog()
	return ..()

/obj/machinery/transhuman/resleever/proc/putmind(var/datum/transhuman/mind_record/MR)
	if(!occupant || !istype(occupant) || occupant.stat >= DEAD)
		return 0

	//In case they already had a mind!
	occupant << "<span class='warning'>You feel your mind being overwritten...</span>"

	//Attach as much stuff as possible to the mob.
	for(var/datum/language/L in MR.languages)
		occupant.add_language(L.name)
	occupant.identifying_gender = MR.id_gender
	occupant.client = MR.client
	occupant.mind = MR.mind
	occupant.ckey = MR.ckey
	occupant.ooc_notes = MR.mind_oocnotes
	occupant.apply_vore_prefs() //Cheap hack for now to give them SOME bellies.

	//Give them a backup implant
	var/obj/item/weapon/implant/backup/new_imp = new()
	if(new_imp.implanted(occupant))
		new_imp.loc = occupant
		new_imp.imp_in = occupant
		new_imp.implanted = 1
		//Put it in the head! Makes sense.
		var/obj/item/organ/external/affected = occupant.get_organ(BP_HEAD)
		affected.implants += new_imp
		new_imp.part = affected

	//Update the database record
	MR.mob_ref = occupant
	MR.imp_ref = new_imp
	MR.secretly_dead = 0
	MR.obviously_dead = 0

	//Inform them and make them a little dizzy.
	occupant << "<span class='warning'>You feel a small pain in your head as you're given a new backup implant. Oh, and a new body. It's disorienting, to say the least.</span>"
	occupant.confused = max(occupant.confused, 25)
	occupant.eye_blurry = max(occupant.eye_blurry, 25)

	return 1

/obj/machinery/transhuman/resleever/proc/go_out(var/mob/M)
	if(!( src.occupant ))
		return
	if (src.occupant.client)
		src.occupant.client.eye = src.occupant.client.mob
		src.occupant.client.perspective = MOB_PERSPECTIVE
	src.occupant.loc = src.loc
	src.occupant = null
	icon_state = "implantchair"
	return

/obj/machinery/transhuman/resleever/proc/put_mob(mob/living/carbon/human/M as mob)
	if(!ishuman(M))
		usr << "<span class='warning'>\The [src] cannot hold this!</span>"
		return
	if(src.occupant)
		usr << "<span class='warning'>\The [src] is already occupied!</span>"
		return
	if(M.client)
		M.client.perspective = EYE_PERSPECTIVE
		M.client.eye = src
	M.stop_pulling()
	M.loc = src
	src.occupant = M
	src.add_fingerprint(usr)
	icon_state = "implantchair_on"
	return 1

/obj/machinery/transhuman/resleever/verb/get_out()
	set name = "EJECT Occupant"
	set category = "Object"
	set src in oview(1)
	if(usr.stat != 0)
		return
	src.go_out(usr)
	add_fingerprint(usr)
	return

/obj/machinery/transhuman/resleever/verb/move_inside()
	set name = "Move INSIDE"
	set category = "Object"
	set src in oview(1)
	if(usr.stat != 0 || stat & (NOPOWER|BROKEN))
		return
	put_mob(usr)
	return
