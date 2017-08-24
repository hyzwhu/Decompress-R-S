Red/System []
TREE!: alias struct! [
	table [int-ptr!]
	trans [int-ptr!]
]
init-TREE: func [
	a [TREE!]
][
	a/table: as int-ptr! allocate 16 * size? integer!
	a/trans: as int-ptr! allocate 288 * size? integer!
]

DATA!: alias struct! [
	source 		[byte-ptr!]   
	tag 		[integer!]
	bitcount	[integer!]
	dest 		[byte-ptr!]       
	destLen 	[int-ptr!]
	ltree 		[TREE! value]
	dtree 		[TREE! value]	
]

sltree: declare TREE!
sdtree: declare TREE!

;--extra bits and base tables for length codes
length-bits: as int-ptr! allocate 30 * size? integer! ;byte->int pointer
length-base: as int-ptr! allocate 30 * size? integer!

;--extra bits and base table for distance codes
dist-bits: as int-ptr! allocate 30 * size? integer!  ;byte->int pointer
dist-base: as int-ptr! allocate 30 * size? integer!

;--special ordring of code length  code
clcidx: [16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15]

	;--build extra bits and base tables
	build-bits-base: func[
		bits 	[int-ptr!]  
		base	[int-ptr!]
		delta 	[integer!]
		first 	[integer!]
		/local
			i 	[integer!]
			sum [integer!]
			j	[integer!]
	][
		;--build bits table
		i: 1
		until[
			bits/i: 0 
			i: i + 1
			i = (delta + 1)
		]

		i: 1   
		until[
			j: i + delta 
			bits/j: i - 1 / delta
			i: i + 1
			i = (31 - delta)
		]

		;--build base table 
		sum: first
		i: 1
		until[
			base/i: sum
			sum: sum + (1 << (bits/i))
			i: i + 1
			i = 31      
		]		
	]

	;--build the fixed huffman trees
	build-fixed-trees: function [
		lt [TREE! ]
		dt [TREE! ]
		/local 
			i [integer!]
			j [integer!]

	][
		;--build fixed length tree
		init-TREE lt
		init-TREE dt
		i: 1
		until[
			lt/table/i: 0
			i: i + 1
			i = 8
		]
		lt/table/8: 24
		lt/table/9: 152
		lt/table/10: 112
		i: 1
		until [
			lt/trans/i: 256 + i - 1
			i: i + 1
			i = 25

		]
		i: 1
		until [
			j: i + 24
			lt/trans/j: i - 1
			i: i + 1
			i = 145

		]
		i: 1
		until [
			j: 168 + i
			lt/trans/j: 280 + i - 1
			i: i + 1
			i = 9
		]

		i: 1
		until [
			j: 176 + i
			lt/trans/j: 144 + i - 1
			i: i + 1
			i = 113
		]

		;--build fixed distance tree
		i: 1
		until[
			dt/table/i: 0
			i: i + 1
			i = 6
		]

		dt/table/6: 32

		i: 1
		until[
			dt/trans/i: i - 1
			i: i + 1
			i = 33
		]
		
		free as byte-ptr! lt/trans
		free as byte-ptr! lt/table
		free as byte-ptr! dt/trans
		free as byte-ptr! dt/table		
	]

	;--given an array of code length,build a tree
	build-tree: func [
		t 		[TREE! ]
		lengths [int-ptr!]  
		num 	[integer!]
		/local
			offs 	[int-ptr!]
			i 		[integer!]
			sum 	[integer!]
			j 		[integer!]
			l 		[integer!]
			k 		[integer!]

	][
		offs: as int-ptr! allocate 70
		;--clear code length count table
		i: 1
		until [
			t/table/i: 0
			i: i + 1
			i = 17
		]

		;--scan symbole lengths, and sum code length counts
		i: 1
		until[
			j: lengths/i + 1
			t/table/j: t/table/j + 1
			i: i + 1
			i = (num + 1)
		]
		t/table/1: 0

		;--compute offset table for distribution sort
		i: 1
		sum: 0
		until[
			offs/i: sum
			sum: sum + t/table/i
			i: i + 1
			i = 17
		]
		

		;--create code->symbol translation table (symbol sorted)
		i: 1
		until[
			j: lengths/i
			k: j + 1
			l: offs/k
			if j > 0 [
				l: l + 1
				t/trans/l: i - 1
				offs/k: offs/k + 1
			
			]
			i: i + 1
			i = (num + 1)

		]
		
		free as byte-ptr! offs
	]


	;--get one bit from source stream
	getbit: func [
		d 		[DATA!]
		return: [integer!]

		/local
			bit [integer!]
			j 	[integer!]
			l	[int-ptr!]
	][
		;--check if tag is empty
		d/bitcount: d/bitcount - 1
		if d/bitcount = 0 [
			;--load next tag
			d/source: d/source + 1 
			d/tag: as integer! d/source/value
			d/bitcount: 8   
		]
		;--shift bit out of tag
		j: d/tag
		d/tag: d/tag >> 1
		j and 01h		
	]

	;--read a num bit value from a stream and add base
	read-bits: func [
		d 		[DATA! ]
		num 	[integer!]
		base 	[integer!]
		return: [integer!]
		/local
			i 		[integer!]
			val 	[integer!]
			limit 	[integer!]
			mask 	[integer!]
	][ 
		val: 0
	;--read num bits
	if num <> 0 [ 
		limit: 1 << num
		mask: 1
		until[
			i: getbit d
			if i <> 0 [
				val: val + mask
			]
			mask: mask * 2
			mask >= limit
		]		
	]
		val + base   
	]   

	;--given a data stream and a tree,decode a symbol
	decode-symbol: func [
		d 		[DATA! ]
		t 		[TREE! ]
		return: [integer!]
		 /local
		 	sum [integer!]
		 	cur [integer!]
		 	len [integer!]
			 i 	[integer!]
			 j 	[integer!]
			 l 	[integer!]
				


	][ 
		sum: 0
		cur: 0
		len: 1
		
		until[
			i: getbit d
			cur: 2 * cur + i
			len: len + 1
			j: t/table/len
			sum: sum + j
			cur: cur - j
			cur < 0
		]
		l: sum + cur + 1
		t/trans/l

	]

	;--given a data stream,decode dynamic trees from it
	decode-trees: func [
	   d 	[DATA! ]
	   lt 	[TREE! ]
	   dt	[TREE! ]
	   /local
		code-tree 	[TREE! value]	   
		lengths		[int-ptr!] 	   
	  	hlit 		[integer!]
	   	hdist 		[integer!]
	   	hclen 		[integer!]
	  	i 			[integer!]
	   	num 		[integer!]
	 	length 		[integer!]
	   	clen 		[integer!]
	   	j 			[integer!]
	   	sym 		[integer!]
	  	prev 		[integer!]
	   	l 			[integer!]
	][  
		init-TREE code-tree

		lengths: as int-ptr! allocate 1400
		;--get 5 bits HLIT (257-286)
		hlit: read-bits d 5 257
		;--get 5 bits HDIST (1-32)
		hdist: read-bits d 5 1
		;--get 4 bits HCLEN (4-19)
		hclen: read-bits d 4 4
		i: 1
		until [
			lengths/i: 0
			i: i + 1
			i = 20
		]

		;--read code lengths for code lengte alphabet
		i: 1
		until [
			;--get 3 bits code length (0-7)
			clen: read-bits d 3 0
			j: clcidx/i + 1
			lengths/j: clen
			i: i + 1
			i = (hclen + 1)

		]
		 
		;--build code length tree
		build-tree code-tree lengths 19

		;--decode code lengths for the dynamic trees
		num: 0
		until [
			sym: decode-symbol d code-tree
			switch sym[
				16 [
					;--copy previous code length 3-6 times (read 2 bits)
					j: num - 1 + 1
					prev: lengths/j
					length: read-bits d 2 3
					until [
						l: num + 1
						lengths/l: prev
						num: num + 1
						length: length - 1
						length = 0
						
					]
					
				]
				

				17 [
					;--repeat code length 0 for 3-10 times (read 3 bits)
					length: read-bits d 3 3
					until [
						l: num + 1
						lengths/l: 0
						num: num + 1
						length: length - 1
						length = 0
						]
						
					]
				

				18 [
					;--repeat code length 0 for 11-138 times (read 7 bits)
					length: read-bits d 7 11
					 until [
						l: num + 1
						lengths/l: 0
						num: num + 1
						length: length - 1
						length = 0
						]
					   
					]
				

				default [
					l: num + 1
					lengths/l: sym
					num: num + 1
					
				]
				

				]
			num >= (hlit + hdist)
		]
		
		;--build dynamic trees
		build-tree lt lengths hlit
		build-tree dt (lengths + hlit) hdist
		free as byte-ptr! lengths
		free as byte-ptr! code-tree/trans
		free as byte-ptr! code-tree/table
	]

	;--given a stream and two trees, inflate a block of data
	inflate-block-data: func [
		d 		[DATA! ]
		lt 		[TREE! ]
		dt 		[TREE! ]
		return: [integer!]
		/local
		start 	[byte-ptr! ]
		sym 	[integer!]
		length 	[integer!]
		dist 	[integer!]
		offs 	[integer!]
		i 		[integer!]
		j 		[integer!]
		l 		[integer!]
		k 		[integer!]
	][
		;--remember current output position
		start: d/dest
		l: 1
		until [
			sym: decode-symbol d lt
			;--check for end of block

			if sym = 256 [
				d/destLen/value: d/destLen/value + (d/dest - start)
				break
			]

			if sym < 256 [
				d/dest/value: as byte! sym
				d/dest: d/dest + 1
			]

			if sym > 256 [
				sym: sym - 257  
				k: sym + 1
				;--possibly get more bits from length code
				length: read-bits d length-bits/k length-base/k
				dist: decode-symbol d dt
				;--possibly get more bits from distance code
				k: dist + 1
				offs: read-bits d dist-bits/k dist-base/k

				;--copy match
				i: 1
				until[
					j: i - offs
					d/dest/i: d/dest/j
					i: i + 1
					i = (length + 1)
				]
				d/dest: d/dest + length
			]
			l < 0
		]
		0		
	] 


	;--inflate an uncompressed block of data
	inflate-uncompressed-block: func[
		d 			[DATA! ]
		return: 	[integer!]
		/local
		length 		[integer!]
		invlength 	[integer!]
		i 			[integer!]
		j			[byte-ptr!]
		l 			[byte-ptr!]
	][
		;--get length
		length: as integer! d/source/2  
		length: 256 * length + d/source/1
		
		;--get one's complement of length
		invlength: as integer! d/source/4 
		invlength: 256 * invlength + d/source/3

		;--check length
		
		d/source: d/source + 4

		;--copy block
		i: length
		until [
			j: d/dest + 1
			l: d/source + 1
			j: l
			i: i - 1
			i = 0
		]

		;--make sure we start next block on a byte boundary
		d/bitcount: 0
		d/destLen: d/destLen + length
		system/stack/free as integer! j
		system/stack/free as integer! l
		0
	]

	;--inflate a block of data compressed with fixed huffman trees
	inflate-fixed-block: func [
			d [DATA! ]
	
	][
		inflate-block-data d sltree sdtree
	]

	;--inflate a block of data compressed with dynamic huffman trees
	inflata-dynamic-block: func [
		d [DATA! ]
	][  
		init-TREE d/ltree
		init-TREE d/dtree
		;--decode trees from stream
		decode-trees d d/ltree d/dtree

		;--decode block using decoded trees
		inflate-block-data d d/ltree d/dtree 
		free as byte-ptr! d/ltree/trans
		free as byte-ptr! d/ltree/table
		free as byte-ptr! d/dtree/trans
		free as byte-ptr! d/dtree/table     
	]

	;--initialize global (static) data
	init: func [][
		;--build fixed huffman trees
		build-fixed-trees sltree sdtree
		;--build extra bits and base tables
		build-bits-base length-bits length-base 4 3 
		build-bits-base dist-bits dist-base 2 1		
		;--fix a special carse
		length-bits/29: 0
		length-base/29: 258		
	]

	;--free the allocated block
	free-block: func [][
		free as byte-ptr! length-bits
		free as byte-ptr! length-base
		free as byte-ptr! dist-base
		free as byte-ptr! dist-bits
	]

	;--inflate stream from source to dest
	uncompress: func [
		dest 		[byte-ptr!] 
		destLen 	[int-ptr!]
		source 		[byte-ptr!]
		sourceLen 	[integer!]
		return:		[integer!]
		/local
		bfinal 		[integer!]
		d 			[DATA! value]
		btype 		[integer!]
		res 		[integer!]
	][
		;--initialise data
		init
		d/source: source
		d/bitcount: 1
		d/dest: dest
		d/destLen: destLen
		destLen/value: 0

		until [
			;--read final block flag
			bfinal: getbit d
			;--read block type (2 bits)
			btype: read-bits d 2 0

			switch btype [
				0 [
					;--decompress uncompressed block
					res: inflate-uncompressed-block d
					break
				]

				1 [
					;--decompress block with fixed huffman trees
					inflate-fixed-block d  
					break
				]

				2 [
					;--decompress block with dynamic huffman trees
					inflata-dynamic-block d
					break
				]

				default [
					break
				]
			]
					;--if res!=ok return error
					bfinal <> 0
		]
		free-block
		 return 0
	]

;----------------------
;----test function-----
;----------------------

#import [
	"zlib.dll" cdecl [
		compress: "compress" [
			dst 	[byte-ptr!]
			dstLen 	[int-ptr!]
			src 	[c-string!]
			srcLen 	[integer!]

			return: [integer!]
		]
	]
]
;--compress data
res: declare integer!
src: "tomorrow, i will learn more konwledge than yestoday,eventhough there are many hard cores"
dst: as byte-ptr! allocate 1000000
dstLen: 1024
srcLen: declare integer!
srcLen: length? src
res: compress dst :dstLen src srcLen
print-line ["return :" res ]
j: 0

;--decompress data
srcLen: dstLen
src1: as byte-ptr! allocate 100000
i: 1
until [
	src1/i: dst/i
	i: i + 1
	i = (srcLen + 1)
]
dst1: as byte-ptr! allocate 100000
c: declare byte!
dstLen1: 1024
src1: src1 + 1
srcLen: srcLen - 6
uncompress dst1 :dstLen1 src1 srcLen
i: 1
until [
	c: as byte! dst1/i
	print [c]
	i: i + 1
	i = dstLen1
]




