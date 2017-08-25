Red/System[]
#include %inflate.reds
#include %infcrc32.reds

#define FTEXT       1
#define FHCRC       2
#define FEXTRA      4
#define FNAME       8
#define FCOMMENT    16

	zip-uncompress: func [
		dest        [byte-ptr!]
		destLen     [int-ptr!]
		source      [byte-ptr!]
		sourceLen   [integer!]
		return:     [integer!]
		/local
			src     [byte-ptr!]
			dst     [byte-ptr!]
			start   [byte-ptr!]
			dlen    [integer!]
			crc   [integer!]
			flg     [byte!]
			xlen    [integer!]
			hcrc    [integer!]
			i       [integer!]
			res     [integer!]
			a       [integer!]
			b       [integer!]
			c       [integer!]
			flga    [integer!]
	][  
		src: as byte-ptr! allocate 1000
		dst: as byte-ptr! allocate 1000
		src: source
		dst: dest
		;--check format
		;--check id bytes
		a: as integer! src/1
		b: as integer! src/2
		if  any[(a <> 1Fh) b <> 8Bh] [
			return -3
		]
		;--check method is deflate
		a: as integer! src/3
		if a <> 8 [
			return -3
		]
		;--get flag byte
		flg: src/4
		flga: as integer! flg
		;--check that reserved bits are zero
		if (flga and E0h) <> 0 [
			return -3
		]
		;--find start of compressed data
		;--skip base header of 10 bytes
		start: src + 10
		;--skip extra data if present
		if (flga and FEXTRA) <> 0 [
			xlen: as integer! start/2
			b: as integer! start/1
			xlen: xlen * 256 + b
			start: start + xlen + 2
		]
		;--skip file comment if present
		if (flga and FNAME) <> 0 [
			c: as integer! start/value
			while [c <> 0][
				start: start + 1
			]
			start: start + 1
		]
		if (flga and FCOMMENT) <> 0 [
		c: as integer! start/value
			while [c <> 0][
				start: start + 1
			]
			start: start + 1
		]
		;--check header crc if present
		if (flga and FHCRC) <> 0 [
			hcrc: as integer! start/2
			a: as integer! start/1
			hcrc: 256 * hcrc + a
			i: CRC32 src size? (start - src)
			if (hcrc <> (i and FFFFh)) [
				return -3
			]
			start: start + 2
		]
		;--get decompressed length
		dlen: as integer! src/sourceLen
		b: as integer!  (sourceLen - 1)
		a: as integer!  src/b
		dlen: 256 * dlen + a
		b: as integer!  sourceLen - 2
		a: as integer!  src/b
		dlen: 256 * dlen + a
		b: as integer!  sourceLen - 3
		a: as integer!  src/b
		dlen: 256 * dlen + a
		;--get crc32 of decompressed data
		b: as integer!  sourceLen - 4
		crc: as integer! src/b
		b: as integer!  sourceLen - 5
		a: as integer!  src/b
		crc: 256 * crc + a
		b: as integer!  sourceLen - 6
		a: as integer!  src/b
		crc: 256 * crc + a
		b: as integer!  sourceLen - 7
		a: as integer!  src/b
		crc: 256 * crc + a
		;--decompress data
		a: as integer! (src + sourceLen - start - 8)
		res: uncompress dst destLen start a
		if res <> 0 [
			return -3
		]
		if (destLen/value) <> dlen [
			return -3
		]
		;--check CRC32 checksum
		c: CRC32 dst dlen
		if crc <> c [
			return -3
		]
		return 0
	]
	