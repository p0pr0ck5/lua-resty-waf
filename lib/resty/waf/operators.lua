return {
    pattern_match = function(needle, haystack)
        for i = 1, #haystack do
            if needle:find(haystack[i], nil, true) then
                return i
            end
        end
    end,
}