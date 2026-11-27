extends RefCounted
## Number formatting for money: $7, $1,240, $12.4K, $3.05M, ... so growth reads at a glance.

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func money(v: float) -> String:
	return "$" + number(v)


static func number(v: float) -> String:
	var neg := v < 0.0
	v = absf(v)
	var s: String
	if v < 10.0 and v != floorf(v):
		s = "%.1f" % v
	elif v < 10000.0:
		s = commas(int(floor(v)))
	else:
		var e := 0
		while v >= 1000.0 and e < SUFFIXES.size() - 1:
			v /= 1000.0
			e += 1
		if v >= 100.0:
			s = "%d%s" % [int(floor(v)), SUFFIXES[e]]
		elif v >= 10.0:
			s = "%.1f%s" % [floor(v * 10.0) / 10.0, SUFFIXES[e]]
		else:
			s = "%.2f%s" % [floor(v * 100.0) / 100.0, SUFFIXES[e]]
	return ("-" if neg else "") + s


static func commas(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
