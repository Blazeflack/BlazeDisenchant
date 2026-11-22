-- Adapted from Disenchantry 1.2.9; see LICENSE and NOTICE.
local _, ns = ...
local uncommon = {
    {5,15,10940,10938,nil,80,20,20,80,1,2,1,2},
    {16,20,10940,10939,10978,75,20,20,75,2,3,1,2},
    {21,25,10940,10998,10978,75,15,15,75,4,6,1,2},
    {26,30,11083,11082,11084,75,20,20,75,1,2,1,2},
    {31,35,11083,11134,11138,75,20,20,75,2,5,1,2},
    {36,40,11137,11135,11139,75,20,20,75,1,2,1,2},
    {41,45,11137,11174,11177,75,20,20,75,2,5,1,2},
    {46,50,11176,11175,11178,75,20,20,75,1,2,1,2},
    {51,55,11176,16202,14343,75,20,22,75,2,5,1,2},
    {56,60,16204,16203,14344,75,20,22,75,1,2,1,2},
    {61,65,16204,16203,14344,75,20,22,75,2,5,2,3},
}

local overrides = {}
local lowCraft = {approximate=true,foreverCraftEstimate=true,
    {itemID=10940,chance=80,minQuantity=2,maxQuantity=3},
    {itemID=10938,chance=20,minQuantity=2,maxQuantity=3}}
local midCraft = {approximate=true,foreverCraftEstimate=true,
    {itemID=10940,chance=75,minQuantity=3,maxQuantity=4},
    {itemID=10939,chance=20,minQuantity=2,maxQuantity=3},
    {itemID=10978,chance=5,minQuantity=2,maxQuantity=2}}
for _,id in ipairs({250620,250482,250621,252424,252425,252426,252427,253885,253887}) do
    overrides[id]=lowCraft
end
for _,id in ipairs({250513,250514,250515,250516,250517,250508,250509,250510,250511,250512,250489,
    252428,252429,252430,252431,252432,252433,252494,252495,252496,252497,252498,252499,
    253889,253891,253893,253895,253897,253899,253901,253903,253905,253907,253909,253911,
    253913,253915,253917,253919,253921,253923}) do
    overrides[id]=midCraft
end

local excluded = {
    [11287]=true, [11288]=true, [11289]=true, [11290]=true,
    [247789]=true, [249144]=true, [249234]=true, [249232]=true,
    [249237]=true, [249385]=true,
}
local rare = {
    {1,25,10978}, {26,30,11084}, {31,35,11138}, {36,40,11139},
    {41,45,11177}, {46,50,11178}, {51,55,14343}, {56,80,14344,20725},
}
local epic = {
    {40,45,11177,2,4}, {46,50,11178,2,4}, {51,55,14343,2,4},
    {56,60,20725,1,1}, {61,88,20725,1,2},
}
local function find(rows, level)
    for _, row in ipairs(rows) do
        if level >= row[1] and level <= row[2] then return row end
    end
end
local function outcome(id, chance, low, high)
    return {itemID=id, chance=chance, minQuantity=low or 1, maxQuantity=high or low or 1}
end

function ns.Results(id, quality, level, classID)
    if excluded[id] or (classID ~= 2 and classID ~= 4) then return nil end
    if not level or level <= 0 then return nil end
    local weapon = classID == 2
    -- Disenchantry's explicit craft guesses and broad new-rare heuristic.
    -- Keep these visibly unverified, without observation-based replacement.
    if quality == 3 and overrides[id] then return overrides[id], true end
    if quality == 3 and id >= 200000 then
        if level < 5 or level > 99 then return nil end
        if level <= 15 then
            return {outcome(10940,weapon and 20 or 80,2,3), outcome(10938,weapon and 80 or 20,2,3)}, true
        elseif level <= 20 then
            return {outcome(10940,weapon and 20 or 75,3,4), outcome(10939,weapon and 75 or 20,2,3), outcome(10978,5,2)}, true
        end
        local row = find(rare, math.min(level,80))
        if row then
            if row[4] then return {outcome(row[3],99.5), outcome(row[4],0.5)}, true end
            return {outcome(row[3],100)}, true
        end
        return nil
    end
    if quality == 2 then
        local row = find(uncommon, level)
        if not row then return nil end
        local dust, essence = row[weapon and 8 or 6], row[weapon and 9 or 7]
        local essenceID = weapon and level >= 21 and level <= 30 and 10939 or row[4]
        local results = {outcome(row[3],dust,row[10],row[11]), outcome(essenceID,essence,row[12],row[13])}
        if row[5] then results[#results+1] = outcome(row[5],100-dust-essence) end
        return results
    elseif quality == 3 then
        local row = find(rare, level)
        if row then
            if row[4] then return {outcome(row[3],99.5),outcome(row[4],0.5)} end
            return {outcome(row[3],100)}
        end
    elseif quality == 4 then
        local row = find(epic, level)
        if row then return {outcome(row[3],100,row[4],row[5])} end
    end
end
