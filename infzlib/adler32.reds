Red/System[]
#define A32-BASE 65531
#define A32-NMAX 5552

	inf-adler32: func[
		data    [byte-ptr!]
		length  [integer!]
		return: [integer!]
		/local
			buf  [byte-ptr!]
			s1   [integer!]
			s2 	 [integer!]
			i    [integer!]
			k    [integer!]
	][
		buf: data
		s1: 1
		s2: 0
		while [length > 0] [
			if length < A32-NMAX [
				k: length
			]
			if length >= A32-NMAX [
				k: A32-NMAX
			]
			i: k / 16
			until [
				s1: s1 + buf/1
				s2: s2 + s1
				s1: s1 + buf/2
				s2: s2 + s1
				s1: s1 + buf/3
				s2: s2 + s1
				s1: s1 + buf/4
				s2: s2 + s1
				s1: s1 + buf/5
				s2: s2 + s1
				s1: s1 + buf/6
				s2: s2 + s1
				s1: s1 + buf/7
				s2: s2 + s1
				s1: s1 + buf/8
				s2: s2 + s1
				s1: s1 + buf/9
				s2: s2 + s1
				s1: s1 + buf/10
				s2: s2 + s1
				s1: s1 + buf/11
				s2: s2 + s1
				s1: s1 + buf/12
				s2: s2 + s1
				s1: s1 + buf/13
				s2: s2 + s1
				s1: s1 + buf/14
				s2: s2 + s1
				s1: s1 + buf/15
				s2: s2 + s1
				s1: s1 + buf/16
				s2: s2 + s1
				buf: buf + 16
				i: i - 1
				i = 0
			]
			i: k % 16
			until [
				k: as integer! buf/value
				s1: s1 + k
				buf: buf + 1
				s2: s2 + 1
				i: i - 1
				i = 0
			]

			s1: s1 % A32-BASE
			S2: S2 % A32-BASE

			length: length - k
		]
		k: s2 << 16
		k or s1
	]