local amount = 1

local eggdv_addr
local atkdef
local spespc
local map_offset
local daycare_flag
local party_offset
local party_size
local cursor
local box_cursor
local box_offset
local box_count
local step_offset
local atkdef_old = 0
local spespc_old = 0
local delay_dv = 0
local retries = 0
local x_coord
local y_coord
local script_running
local menu_option
local party_screen
local version = memory.readbyte(0x141)
local region = memory.readbyte(0x142)
local running = true
if version == 0x54 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Crystal detected")
        eggdv_addr = 0xdf90
        daycare_flag = 0xdef5
        map_offset = 0xdcb6
		party_offset = 0xdcd7
		cursor = 0xcfa9
		box_offset = 0xad10
		box_cursor = 0xCB2B
		step_offset = 0xdf2d
		x_coord = 0xd4e8
		y_coord = 0xd4e9
		script_running = 0xd437
		menu_option = 0xcfb9
		party_screen = 0xcfb6
    elseif region == 0x45 then
        print("USA Crystal detected")
        eggdv_addr = 0xdf90
        daycare_flag = 0xdef5
        map_offset = 0xdcb6
		party_offset = 0xdcd7
    elseif region == 0x4A then
        print("JPN Crystal detected")
        eggdv_addr = 0xdf06
        daycare_flag = 0xde89 
    end
elseif version == 0x55 or version == 0x58 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Gold/Silver detected")
        eggdv_addr = 0xdcdb
        daycare_flag = 0xdc40
    elseif region == 0x45 then
        print("USA Gold/Silver detected")
        eggdv_addr = 0xdcdb
        daycare_flag = 0xdc40
    elseif region == 0x4A then
        print("JPN Gold/Silver detected")
        eggdv_addr = 0xdc51
        daycare_flag = 0xdbd4 
    elseif region == 0x4B then
        print("KOR Gold/Silver detected")
        eggdv_addr = 0xddd8
        daycare_flag = 0xdd3d 
    end
else
    print(string.format("Unknown version, code: %4x", version))
    print("Script stopped")
    return
end

function shiny(atkdef,spespc)
    if spespc == 0xAA then
        if atkdef == 0x2A or atkdef == 0x3A or atkdef == 0x6A or atkdef == 0x7A or atkdef == 0xAA or atkdef == 0xBA or atkdef == 0xEA or atkdef == 0xFA then
            return true
        end
    end
    return false
end

function press(button, delay)
    i = 0
    while i < delay do
        joypad.set(1, button)
        i = i + 1
        emu.frameadvance()
    end
end

function walk_x(x)
	while memory.readbyte(x_coord) < x do
		press({right = true}, 2)
	end
	while memory.readbyte(x_coord) > x do
		press({left = true}, 2)
	end
end

function walk_y(y)
	while memory.readbyte(y_coord) < y do
		press({down = true}, 2)
	end
	while memory.readbyte(y_coord) > y do
		press({up = true}, 2)
	end
end

function walk()
	walk_x(12)
	walk_x(14)
end

function wait_egg()
	print("Waiting for egg...")
	walk_y(9)
    while memory.readbyte(map_offset) == 0x18 do
        press({left = true}, 10); press({left = false}, 10)
    end
	state_steps = savestate.create()
	while memory.readbyte(step_offset) > 0x0F do
		walk()
	end
	savestate.save(state_steps)
	print("Narrowing down steps...")
    while true do
		while memory.readbyte(step_offset) < 0x0F and memory.readbyte(daycare_flag) ~= 0xC1 do
			walk()
		end
		if memory.readbyte(daycare_flag) ~= 0xC1 then
			savestate.load(state_steps)
			memory.readbyte(map_offset)
			math.randomseed( os.time() )
			press({A = true}, math.random(60)); press({A = false}, 10)
            press({B = true}, math.random(60)); press({B = false}, 10)
		else
			break
		end
    end
    while memory.readbyte(map_offset) ~= 0x18 do
    	press({right = true}, 10); press({right = false}, 10)
    end
    walk_x(6)
    while memory.readbyte(map_offset) == 0x18 do
         press({down = true}, 10); press({down = false}, 10)
    end
    while memory.readbyte(script_running) ~= 0 do
		emu.frameadvance()
	end
end

function get_egg()
	print("Collecting egg...")
	walk_x(18)
	while memory.readbyte(daycare_flag) ~= 0xA1 do
		press({A = true}, 10); press({A = false}, 10)
	end
	while memory.readbyte(menu_option) ~= 0xD6 do
		press({A = true}, 2); press({A = false}, 2)
	end
    while memory.readbyte(script_running) ~= 0 do
		press({A = true}, 2); press({A = false}, 2)		--shouldn't be necessary but additional A inputs to decrease likelihood of getting stuck here.
	end
	walk_x(17)
	while memory.readbyte(map_offset) ~= 0x18 do
		press({up = true}, 10); press({up= false}, 10)
    end
end

function take_parent()
	print("Taking parent from Daycare...")
	while memory.readbyte(daycare_flag) ~= 0x81 do
		press({A = true}, 2); press({A = false}, 2)
	end
	while memory.readbyte(menu_option) ~= 0xD6 do
		press({A = true}, 2); press({A = false}, 2)
   	end
end

function leave_parent()
	while memory.readbyte(party_screen) ~= 0x91 do
		press({A = true}, 2); press({A = false}, 2)
   	end
	while memory.readbyte(cursor) ~= party_size do
		press({down = true}, 2); press({down = false},2)	
   	end
	while memory.readbyte(party_screen) ~= 0xE9 do
		press({A = true}, 2); press({A = false}, 2)
   	end
	while memory.readbyte(menu_option) ~= 0xC5 do
		emu.frameadvance()
	end
	for i=0,1,1 do
		press({A = true}, 5); press({A = false}, 5)
   	end
end

function drop_egg()
	print("Dropping egg in PC!")
	walk_x(9)
	walk_y(8)
	walk_x(11)
	walk_y(6)
	--standing at PC
	if memory.readbyte(box_offset) == 20 then
		print("Your box is full! Shiny egg is in your party.\nStopping script.")
		running = false
		return
	end
	while memory.readbyte(cursor) ~= 1 do
		press({A = true}, 2); press({A = false},2)	
   	end
	
	while memory.readbyte(menu_option) ~= 0x80 do
		press({A = true}, 2); press({A = false}, 2)
   	end
	while memory.readbyte(cursor) ~= 2 do
		press({down = true}, 2); press({down = false},2)	
   	end
	press({A = true}, 2); press({A = false}, 2)
	while memory.readbyte(menu_option) ~= 0x0A do
		emu.frameadvance()
   	end
	while memory.readbyte(box_cursor) ~= (party_size-1) do
		press({down = true}, 2); press({down = false},2)	
   	end
	while memory.readbyte(script_running) ~= 0x01 do
		emu.frameadvance()
	end
	while memory.readbyte(menu_option) ~= 0x80 do
		press({A = true}, 2); press({A = false}, 2)
	end
	press({A = true}, 2); press({A = false}, 2)
	press({A = true}, 2); press({A = false}, 2)
	if memory.readbyte(box_offset) == 20 then
		print("Your box is full! Shiny egg is in your party.\nStopping script.")
		running = false
		return
	end
	while memory.readbyte(menu_option) ~= 0x0A do
		press({B = true}, 2); press({B = false}, 2)
   	end
	while memory.readbyte(menu_option) ~= 0xD6 do
		press({B = true}, 2); press({B = false}, 2)
   	end
	walk_y(8)
	walk_x(9)
	press({up = true}, 10); press({up = false}, 10)
end	
 
state = savestate.create()

while running do
    savestate.save(state)
    max_size = 20 - amount
    party_size = memory.readbyte(party_offset)
    if party_size > 5 then
		print("Your team doesn't have enough room!")
		break
    end	
    for i = 1, 105 do
        joypad.set(1, {A=true})
        emu.frameadvance()
    end
	for i = 1, delay_dv do
		emu.frameadvance()
	end
    atkdef = memory.readbyte(eggdv_addr)
    spespc = memory.readbyte(eggdv_addr + 1)
    print(string.format("Atk: %d Def: %d Spe: %d Spc: %d", math.floor(atkdef/16), atkdef%16, math.floor(spespc/16), spespc%16))
    if shiny(atkdef, spespc) then
	--if 0 == 0 then
        print("Shiny!!!")
	    while memory.readbyte(menu_option) ~= 0xD6 do
			press({A = true}, 2); press({A = false}, 2)
		end
	    while memory.readbyte(script_running) ~= 0 do
			emu.frameadvance()
		end
        wait_egg()
	    get_egg()
		party_size = party_size +1
		drop_egg()
		if running ~= true then
			break
		end
		party_size = party_size -1
	    take_parent()
	    party_size = party_size + 1
	    amount = amount - 1
	    if amount == 0 then
			savestate.save(state)
			break
	    end
	    leave_parent()
        party_size = party_size - 1

    else
		if atkdef == atkdef_old and spespc == spespc_old then
			if (retries % 4) < 3 then
				retries = retries + 1
			else
				retries = 0
				delay_dv = delay_dv + 10
				print("DVs are not changing. Calibration in progress...")
			end
		else
			atkdef_old = atkdef
			spespc_old = spespc
		end
        print("discard!")
        savestate.load(state)
    end
    emu.frameadvance()
end
