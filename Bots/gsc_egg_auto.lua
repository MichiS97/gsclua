local eggdv_addr
local atkdef
local spespc
local amount = 3
local map_id
local map_offset
local daycare_flag
local party_offset
local party_size
local cursor

local version = memory.readbyte(0x141)
local region = memory.readbyte(0x142)
if version == 0x54 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Crystal detected")
        eggdv_addr = 0xdf90
        daycare_flag = 0xdef5
        map_offset = 0xdcb6
	party_offset = 0xdcd7
	cursor = 0xcfa9
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

function wait_egg()
    press({down = true}, 10); press({down = false}, 10)
    while memory.readbyte(map_offset) == 0x18 do
        press({left = true}, 10); press({left = false}, 10)
    end
    while memory.readbyte(daycare_flag) ~= 0xC1 do
 	if memory.readbyte(map_offset) ~= 0x18 then
		press({left = true}, 10); press({left = false}, 10)
        	press({right = true}, 10); press({right = false}, 10)
	end
	if memory.readbyte(map_offset) == 0x18 then
		press({left = true}, 10); press({left = false}, 10)
		press({left = true}, 10); press({left = false}, 10)
	end
    end
    while memory.readbyte(map_offset) ~= 0x18 do
    	press({right = true}, 10); press({right = false}, 10)
    end
    for i=0,2,1 do
	press({right = true}, 10); press({right = false}, 10)
    end
    while memory.readbyte(map_offset) == 0x18 do
         press({down = true}, 10); press({down = false}, 10)
    end
    for i = 1, 60 do
	emu.frameadvance()
    end
end

function get_egg()
	press({right = true}, 10); press({right = false}, 10)
	while memory.readbyte(daycare_flag) ~= 0xA1 do
		press({A = true}, 10); press({A = false}, 10)
	end
	for i = 1, 120 do
		emu.frameadvance()
	end
        press({A = true}, 10); press({A = false}, 10)
	for i = 1, 60 do
		emu.frameadvance()
	end
        press({A = true}, 10); press({A = false}, 10)
        for i = 1, 240 do
		emu.frameadvance()
	end
	press({left = true}, 10); press({left = false}, 10)
	while memory.readbyte(map_offset) ~= 0x18 do
		press({up = true}, 10); press({up= false}, 10)
    	end
end

function take_parent()
	for i=0,3,1 do
		press({right = true}, 10); press({right = false}, 10)
   	end
	for i=0,3,1 do
		press({up = true}, 10); press({up = false}, 10)
   	end
	while memory.readbyte(daycare_flag) ~= 0x81 do
		press({A = true}, 10); press({A = false}, 10)
	end
	for i = 1, 60 do
		emu.frameadvance()
	end
        press({A = true}, 10); press({A = false}, 10)
end

function leave_parent()
	while memory.readbyte(0x8000) ~= 0 do
		press({A = true}, 10); press({A = false}, 10)	
   	end
	while memory.readbyte(cursor) ~= party_size do
		press({down = true}, 2); press({down = false},2)	
   	end
	press({A = true}, 10); press({A = false}, 10)
	
	for i = 1, 240 do
		emu.frameadvance()
	end
	for i=0,1,1 do
		press({A = true}, 5); press({A = false}, 5)
   	end
end
	
 
state = savestate.create()

while true do
    savestate.save(state)
    max_size = 5 - amount
    party_size = memory.readbyte(party_offset)
    if party_size > max_size then
	print("Your team doesn't have enough room!")
	break
    end	
    for i = 1, 105 do
        joypad.set(1, {A=true})
        emu.frameadvance()
    end
    atkdef = memory.readbyte(eggdv_addr)
    spespc = memory.readbyte(eggdv_addr + 1)
    print(string.format("Atk: %d Def: %d Spe: %d Spc: %d", math.floor(atkdef/16), atkdef%16, math.floor(spespc/16), spespc%16))
    if shiny(atkdef, spespc) then
            print("Shiny!!!")
	    for i = 1, 60 do
		emu.frameadvance()
	    end
	    press({A = true}, 10); press({A = false}, 20)
	    for i = 1, 30 do
		emu.frameadvance()
	    end
            wait_egg()
	    get_egg()
	    party_size = party_size + 1
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
        print("discard!")
        savestate.load(state)
    end
    emu.frameadvance()
end
