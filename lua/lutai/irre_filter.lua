---删除掉 yi,ji,bl 音节是 一、几、百的候选

local snow = require "lutai.snow"

---@type string[]
local syllables = {}

---@param text string
---@return boolean
local function split(text)
    local syllable = rime_api.regex_search(text, "[qwertyuiopasfghjklzxcvbnm][a-z](?:d[a-z]){0,2}$")
    if syllable then
        local has_irre = false
        local len = 0
        for _, _syllable in ipairs(syllable) do
            table.insert(syllables, _syllable)
            len = #_syllable
            if rime_api.regex_match(_syllable, "(?:yi|ji|bl).*") then
                has_irre = true
            end
        end
        local front = split(text:sub(1, #text - len))
        return has_irre or front
    end
    if #text > 0 then
        table.insert(syllables, text)
    end
    return false
end

---@param input Translation
---@param env Env
local function irre_filter(input, env)
    local map = {}
    map["yi"] = "一"
    map["ji"] = "几"
    map["bl"] = "百"
    local code = snow.current(env.engine.context)
    if not code then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    syllables = {}
    local has_irre = split(code)
    if not has_irre then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    for cand in input:iter() do
        if utf8.len(cand.text) ~= #syllables then
            yield(cand)
        end
        local passed = true
        for i = 1, #syllables do
            if #syllables ~= utf8.len(cand.text) then
                break
            end
            if not passed then
                break
            end
            if map[syllables[#syllables - i + 1]:sub(1, 2)] == snow.sub(cand.text, i, i) then
                passed = false
            end
        end
        if passed then
            yield(cand)
        end
    end
end

return irre_filter
