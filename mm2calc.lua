local Api = {};

-- [define as upvalues for 0.00001% speed increase]
--functions
local sub = string.sub;
local find = string.find;
local split = string.split;
local remove = table.remove;
local gsub = string.gsub;
local insert = table.insert;
local match = string.match;
local tonumber = tonumber;

local pcall = pcall;
local error = error;
local tostring = tostring;

local assert = assert;

-- local httpget : (string) -> (none,string);do -- v3 has actual luau, v2 doesn't
local httpget; do
    local game = game;
    local oldhttpget = game.HttpGet;
    httpget = function(url)
        local suc, res = pcall(oldhttpget, game, url); -- game:HttpGet(url)
        if not suc then
            return error("Failed to send get request: " .. tostring(res));
        end;

        return res;
    end;
end;

if game.GameId == 66654135 then -- Murder Mystery
    Api.Game = "MurderMystery2";
    local Pattern = "<font size=%+1><b><span class=(%b><)/span><BR>[%s]+VALUE: ([%d,]+) </b>[%s]+</font>";
    local Pattern2 = "<font size=%+1><b><span class=[^>]+(%b><)/span><BR>[%s]+VALUE: ([%d,]+) </b>[%s]+</font>";
    local BASEURL = "https://www.mm2values.com/v3/?p=";
    local urls = {
        ancient = true,
        unique = true,
        godly = true,
        vintage = true,
        legend = true,
        rare = true,
        uncommon = true,
        common = true,
        pets = true,
        misc = true,
    };
    for k in next, urls do
        urls[k] = BASEURL .. k;
    end;

    function Api.refresh(self)
        assert(self == Api, "Use colon notation. Try self:refresh()");

        local Values = {};
        for Name, Url in next, urls do
            local Body = httpget(Url);

            local function add(Name, Value)
                Name = Name:sub(2, -2); -- get rid of ">" and "<" (first and last characters)
                Value = tonumber((Value:gsub("%D",""))); --extra set of parenthesis are important since tonumber can take a second parameter

                Values[Name:upper()] = Value;
            end;
            Body:gsub(Pattern, add);
            Body:gsub(Pattern2, add);
        end;

        self.Values = Values;
        return Values;
    end;
else
    Api.Game = "Assassin";
    --strings
    local pattern1 = '<body class="docs%-gm">';
    local splitseperator = '<tr style="height: 20px">';
    local namepattern = 'dir="ltr">([^<]+)</td>';
    local clickme = "CLICK ME";
    local na = "N/A";
    local newgt = "NEW &gt;";
    local spaces = "(%s+)";
    local singlequote_escape = "&#39;";
    local singlequote = "'";
    local space = " ";
    local spaces2 = "%s";
    local emptystring = "";
    -- local star = "\226";
    local letters = "%a";
    local T1Exotics = "T1 Exotic[s]?";
    local not_numbers = "%D";

    local URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTSEzyLExxmRJE-YgEkG82hCEzikPPU0dG-EMY3vy7pSYiCgFQofWXpXypyuRkejYlBVwwkOSdpitTI/pubhtml";
    function Api.refresh(self)
        assert(self == Api, "Use colon notation. Try self:refresh()");

        local Body = httpget(URL);
        Body = sub(Body, find(Body, pattern1), -1);
        -- Body = Body:sub(Body:find(pattern1), -1);

        -- local split = Body:split(splitseperator);
        local split = split(Body, splitseperator);
        -- table.remove(split, 1);
        remove(split, 1);

        local Values = {};
        for _, v in next, split do
            -- if v:find(clickme) or v:find(na) then
            if (find(v, clickme) or find(v, na)) and find(v, namepattern) then
                -- if v:find(namepattern) then
                local ltrs = {};
                -- v:gsub(namepattern, function(a)table.insert(ltrs, a)end);
                gsub(v, namepattern, function(a)
                    insert(ltrs, a);
                end);
                if #ltrs < 2 then
                    continue;
                end;
                local first = ltrs[1];
                if first == newgt then
                    continue;
                end;
                -- first = first:gsub(spaces, " ");
                first = (gsub(first, spaces, space));
                -- first = first:gsub(singlequote, "'");
                first = (gsub(first, singlequote_escape, singlequote));
                -- if first:sub(-1,-1):match(spaces2) then
                if match(sub(first, -1, -1), spaces2) then -- last character of first
                    -- first = first:sub(1, -2);
                    first = sub(first, 1, -2); -- cut off the last letter
                end;

                -- local second = ltrs[2]:gsub(spaces2, "");
                local second = gsub(ltrs[2], spaces2, emptystring);
                -- this checked for stars instead of like NONTRADABLE which was pretty dumb
                -- -- if not second:sub(1,1) == star then
                -- if sub(second, 1, 1) ~= star then
                --     continue;
                -- end;

                local third = ltrs[3];
                local oldthird = third;
                -- if third:match(letters) and not third:match(Exotics) then
                if match(third, letters) and not match(third, T1Exotics) then
                    continue;
                end;
                -- third = third:gsub(not_numbers, "");
                third = (gsub(third, space .. T1Exotics, emptystring));
                third = (gsub(third, not_numbers, emptystring));

                Values[first] = tonumber(third); --first is knife, third is value
            end;
        end;

        self.Values = Values;
        return Values;
    end;
end;

local type = type;
local format = string.format;
local clamp = math.clamp;
local abs = math.abs;
local upper = string.upper;
local warn = warn;
function Api.calculate(self, items)
    assert(self == Api, "Use colon notation. Try self:calculate(items)");
    assert(type(items) == "table", "Expected 'table' for items, got " .. type(items) .. ". Pass through a table with itemname = amount. Ex: {Spider = 1} for having one Spider.");

    local Value = 0;

    for Item, Amount in next, items do
        if type(Item) ~= "string" then
            return error("Unexpected key in items. Expected 'string', got " .. format("%q", Item) .. " (" .. type(Item) .. ")");
        end;
        if type(Amount) ~= "number" then
            return error("Unexpected value in items. Expected 'number', got " .. format("%q", Amount) .. " (" .. type(Amount) .. ")");
        end;
        Amount = clamp(Amount, 0, abs(Amount)) -- keep Amount above 0
        Item = upper(Item);

        local value = self.Values[Item];
        if value then
            Value += (value * Amount);
        else
            warn("Item '" .. Item .. "' was not found in values.");
        end;
    end;

    return Value;
end;
function Api.format(self, number)
    assert(self == Api, "Use colon notation. Try self:format(number)");
    assert(type(number) == "number", "Expected 'number' for number, got " .. type(number));

    number = tostring(number);
    if #number < 4 then return number;end;

    -- reverses the string, adds commas to the end of each set of three numbers,
    -- reverses the string back, removes comma at begginging if present
    -- ex: 120346
    -- 643021    -- reverse
    -- 643,021,  -- add commas to the ends of sets of three
    -- ,120,346  -- reverse
    -- 120,346   -- remove comma

    local formatted = (number:reverse():gsub("%d%d%d", "%0,")):reverse();
    if formatted:sub(1,1) == "," then
        formatted = formatted:sub(2, -1);
    end;

    return formatted;
end;

Api:refresh();
shared.UniversalValueApi = Api;
return Api;