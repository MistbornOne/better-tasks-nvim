local M = {}

function M.parse(input)
	input = input:lower():gsub("^@", ""):gsub(",", ""):gsub("[/-]", " ")

	local today = os.time()

	if input == "today" then
		return os.date("%m-%d-%Y", today)
	elseif input == "tomorrow" then
		return os.date("%m-%d-%Y", today + 86400)
	elseif input:match("^%d%d?%s+%a+$") or input:match("^%a+%s+%d%d?$") then
		local month_str = input:match("%a+")
		local day = tonumber(input:match("%d+"))

		local month_map = {
			january = 1,
			jan = 1,
			february = 2,
			feb = 2,
			march = 3,
			mar = 3,
			april = 4,
			apr = 4,
			may = 5,
			june = 6,
			jun = 6,
			july = 7,
			jul = 7,
			august = 8,
			aug = 8,
			september = 9,
			sep = 9,
			sept = 9,
			october = 10,
			oct = 10,
			november = 11,
			nov = 11,
			december = 12,
			dec = 12,
		}

		local month = month_map[month_str]
		if month and day then
			local now = os.date("*t")
			local t = { year = now.year, month = month, day = day }
			local time = os.time(t)
			local valid = os.date("*t", time)
			if valid.month == month and valid.day == day then
				return os.date("%m-%d-%Y", time)
			end
		end
	elseif input:match("^next%s+%a+$") then
		local weekdays = {
			sunday = 1,
			sun = 1,
			monday = 2,
			mon = 2,
			tuesday = 3,
			tue = 3,
			wednesday = 4,
			wed = 4,
			thursday = 5,
			th = 5,
			thurs = 5,
			friday = 6,
			fri = 6,
			saturday = 7,
			sat = 7,
		}

		local target_day = weekdays[input:match("%a+$")]
		if not target_day then
			return nil
		end

		local now = os.date("*t", today)
		local current_day = now.wday
		local days_until = (target_day - current_day + 7) % 7
		days_until = days_until == 0 and 7 or days_until

		return os.date("%m-%d-%Y", today + days_until * 86400)
	end

	return nil
end

return M
