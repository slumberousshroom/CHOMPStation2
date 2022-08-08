#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif


/obj/item/weapon/circuitboard/precisioneditor
	name = T_BOARD("biochemical manipulator")
	build_path = /obj/item/weapon/circuitboard/precisioneditor
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_DATA = 3, TECH_BIO = 3)
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)
