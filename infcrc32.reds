Red/System[]
crc32-table: as int-ptr! allocate 256 * size? integer!
	make-crc32-table: func [
		/local
			c	        [integer!]
			n	        [integer!]
			k	        [integer!]
	][
		n: 1
		until [
			c: n - 1
			k: 0
			until [
				c: either zero? (c and 1) [c >>> 1][c >>> 1 xor EDB88320h]
				k: k + 1
				k = 8
			]
			crc32-table/n: c
			n: n + 1
			n = 257
		]
	]
	CRC32: func [
		"Calculate the CRC32b value for the input data."
		data	[byte-ptr!]
		len		[integer!]
		return:	[integer!]
		/local
			c	[integer!]
			n	[integer!]
			i	[integer!]
	][
		c: FFFFFFFFh
		n: 1
        make-crc32-table
		len: len + 1
		while [n < len][
			i: c xor (as-integer data/n) and FFh + 1
			c: c >>> 8 xor crc32-table/i
			n: n + 1
		]

		not c
	]