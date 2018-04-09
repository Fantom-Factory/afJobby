
internal const class DurationLocale {
	
	static Str approx(Duration duration) {
		// I must be able to come up with a decent DurationBuilder rather than this rubbish...!
		
		hours := duration.toHour
		if (hours == 0)
			return "Just now"
		if (hours == 1)
			return "${hours} hour"
		if (hours <= 24)
			return "${hours} hours"
		
		days := duration.toDay
		if (days == 1)
			return "${days} day"
		if (days <= 7)
			return "${days} days"

		weeks := days / 7
		if (weeks == 1)
			return "${weeks} week"
		if (weeks <= 5)
			return "${weeks} weeks"

		months := days / 30
		if (months == 1)
			return "${months} month"
		if (months <= 11)
			return "${months} months"

		years := days / 365
		if (years == 1)
			return "${years} year"

		return "${years} years"
	}
}
