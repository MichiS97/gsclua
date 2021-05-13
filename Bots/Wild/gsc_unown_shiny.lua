--Edit parameters in this section
local desired_letters = {'I'}
--End of parameters

local atkdef
local spespc
local discardcount = 0
local enemy_addr
local version = memory.readbyte(0x141)
local region = memory.readbyte(0x142)
if version == 0x54 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Crystal detected")
        enemy_addr = 0xd20c
    elseif region == 0x45 then
        print("USA Crystal detected")
        enemy_addr = 0xd20c
    elseif region == 0x4A then
        print("JPN Crystal detected")
        enemy_addr = 0xd23d
    end
elseif version == 0x55 or version == 0x58 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Gold/Silver detected")
        enemy_addr = 0xd0f5
    elseif region == 0x45 then
        print("USA Gold/Silver detected")
        enemy_addr = 0xd0f5
    elseif region == 0x4A then
        print("JPN Gold/Silver detected")
        enemy_addr = 0xd0e7
    elseif region == 0x4B then
        print("KOR Gold/Silver detected")
        enemy_addr = 0xd1b2
    end
else
    print(string.format("Unknown version, code: %4x", version))
    print("Script stopped")
    return
end

local species_addr = enemy_addr - 0x8
local dv_flag_addr = enemy_addr + 0x21
local battle_flag_addr = enemy_addr + 0x22

function getUnownForm(atkdef,spespc)
    spcbits = math.floor(spespc/2) % 4 
    spebits = math.floor(spespc/32) % 4
    defbits = math.floor(atkdef/2) % 4
    atkbits = math.floor(atkdef/32) % 4
    formid = math.floor((atkbits * 64 + defbits * 16 + spebits * 4 + spcbits) / 10)
    return string.char(formid + 65)
end

function shiny(atkdef,spespc)
    if spespc == 0xAA then
        if atkdef == 0x2A or atkdef == 0x3A or atkdef == 0x6A or atkdef == 0x7A or atkdef == 0xAA or atkdef == 0xBA or atkdef == 0xEA or atkdef == 0xFA then
            return true
        end
    end
    return false
end

local state = savestate.create()
while true do
    savestate.save(state)
	found = false
    i = 0
    while memory.readbyte(battle_flag_addr) == 0 do
        if i <15 then
            joypad.set(1, {left=false})
            joypad.set(1, {right=true})
        else
            joypad.set(1, {right=false})
            joypad.set(1, {left=true})
        end
        emu.frameadvance()
        i = (i+1)%32
    end

    if memory.readbyte(species_addr) ~= 201 then
        print("Inproper location for Unown")
        print("Script stopped")
        return
    else
        while memory.readbyte(dv_flag_addr) ~= 0x01 do
            emu.frameadvance()
        end

        -- DVs Reroll
        emu.frameadvance()

        atkdef = memory.readbyte(enemy_addr)
        spespc = memory.readbyte(enemy_addr + 1)
        print(string.format("Atk: %d Def: %d Spe: %d Spc: %d", math.floor(atkdef/16), atkdef%16, math.floor(spespc/16), spespc%16))

        Form = getUnownForm(atkdef,spespc)
        print(string.format("Form: %s", Form))
		
		
		for _,x in ipairs(desired_letters) do
			if Form == x then
				found = true
			end
		end
		if discardcount % 100 == 0 then
			print(discardcount)
		end
        if found and shiny(atkdef, spespc) then
		--if found then
            print(string.format("Desired unown found after %d tries!!!", discardcount))
            savestate.save(state)
            break
        else
			discardcount = discardcount + 1
            savestate.load(state)
        end
    end
    emu.frameadvance()
end
