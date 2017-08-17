Red/System []
TREE!: alias struct! [
    table [int-ptr!]
    trans [int-ptr!]
]
init-TREE: func [
    a [TREE!]
][
    a/table: as int-ptr! allocate 70
    a/trans: as int-ptr! allocate 1100
]

DATA!: alias struct! [
    source1 [int-ptr!]   ;byte->int pointer
    tag [integer!]
    bitcount [integer!]

    dest [int-ptr!]       ;byte->int pointer
    destLen [int-ptr!]

   
    ; ltree [TREE!]
    ; rtree [TREE!]
    ltree [TREE! value]
    dtree [TREE! value]
    
    
]
;---------------------------------------------------
;--uninitialized global data (static structures)----
;---------------------------------------------------
sltree: declare TREE!
sdtree: declare TREE!
; b: declare DATA!
; ; b/ltree: declare TREE!
; ; b/rtree: declare TREE!
; init-TREE b/ltree
; init-TREE b/rtree

; b/ltree/trans/1: 35
; b/ltree/table/1: 13
; print-line ["b/ltree/trans/1:"b/ltree/trans/1]
; print-line ["b/ltree/table/1:"b/ltree/table/1]


;--extra bits and base tables for length codes--
length-bits: as int-ptr! allocate 130  ;byte->int pointer
length-base: as int-ptr! allocate 130

;--extra bits and base table for distance codes--
dist-bits: as int-ptr! allocate 130  ;byte->int pointer
dist-base: as int-ptr! allocate 130

;--special ordring of code length  code--
clcidx: [16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15]

;--build extra bits and base tables--
build-bits-base: func[
    bits [int-ptr!]  ;byte-ptr！ ？？
    base [int-ptr!]
    delta [integer!]
    first1 [integer!]

    /local
    i [integer!]
    sum [integer!]
    j [integer!]
][
    ;--build bits table --
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

    ;--build base table -- 
    sum: first1
    i: 1
    until[
        base/i: sum
        sum: sum + (1 << (bits/i))
        i: i + 1
        i = 31      
    ]

    
]

;--build the fixed huffman trees--
build-fixed-trees: function [
    lt [TREE! ]
    dt [TREE! ]

    /local 
    i [integer!]
    j [integer!]

][
    ;--build fixed length tree--
   ; print-line "int the fixed trees 1"
    ;--test--
    init-TREE lt
    init-TREE dt
    i: 1
    until[
        lt/table/i: 0
        i: i + 1
        i = 8
    ]
    ;print-line "in the fixed 1"
    lt/table/8: 24
    lt/table/9: 152
    lt/table/10: 112
    ;print-line "in the fixed 2"
    i: 1
    until [
        lt/trans/i: 256 + i - 1
        i: i + 1
        i = 25

    ]
   ; print-line "in the fixed 3"
      i: 1
    until [
        j: i + 24
        lt/trans/j: i - 1
        i: i + 1
        i = 145

    ]
   ; print-line "in the fixed 4"
    i: 1
    until [
        j: 168 + i
        lt/trans/j: 280 + i - 1
        i: i + 1
        i = 9
    ]
   ; print-line "in the fixed 5"
    i: 1
    until [
        j: 176 + i
        lt/trans/j: 144 + i - 1
        i: i + 1
        i = 113
    ]
  ;  print-line "in the fixed 6"
    ;--build fixed distance tree--
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
    

    
]

;--given an array of code length,build a tree--
build-tree: func [
    t [TREE! ]
    lengths [int-ptr!]   ;byte->int  pointer
    num [integer!]
    /local
    offs [int-ptr!]
    i [integer!]
    sum [integer!]
    j [integer!]
    l [integer!]
    k [integer!]

][
    print-line ["welcome to build tree"]
    offs: as int-ptr! allocate 70
    print-line "welcome to build tree111111111"
    ;--clear code length count table--
    i: 1
    until [
        t/table/i: 0
        i: i + 1
        i = 17
    ]
    print-line "build tree work 2222222222222"
    ;--scan symbole lengths, and sum code length counts--
    i: 1
    until[
        j: lengths/i + 1
        ;print-line ["the t/table/j's value is:"t/table/j]
        ;print-line ["the lengths/i 's value is:"lengths/i]
        t/table/j: t/table/j + 1
        i: i + 1
        i = (num + 1)
    ]
    print-line "build tree work 2"
    t/table/1: 0
    
    i: 1
    until[
        print-line ["the t/table/i 's value is "t/table/i]
        i: i + 1
        i = (num + 1)
    ]

    ;--compute offset table for distribution sort--
    i: 1
    sum: 0
    until[
        offs/i: sum
        sum: sum + t/table/i
        print-line ["the sum's value is:"sum]
        i: i + 1
        i = 17
    ]
    ;--test--
    

    ;--create code->symbol translation table (symbol sorted) 
    i: 1
    until[
        j: lengths/i
        k: j + 1
        l: offs/k
        if j > 0 [
            print-line ["the lengths/i's value is:"j]
            l: l + 1
            t/trans/l: i - 1
            offs/k: offs/k + 1
           
        ]
        i: i + 1
        i = (num + 1)

    ]
    ;--test--
    i: 1
    until[
        print-line ["the t/trans/i's value is:"t/trans/i]
        i: i + 1
        i = 20
    ]
]

;---------------------
;---decode  function--
;---------------------

    ;--get one bit from source stream--
    getbit: func [
        d [DATA!]
        return: [integer!]

        /local
        bit  [integer!]
        j [integer!]
        l [int-ptr!]
    ][
        ;--check if tag is empty
       
        d/bitcount: d/bitcount - 1
        if d/bitcount = 0 [
            ;--load next tag--
          ;  print-line "load next tag"
            d/source1: d/source1 + 1 ;1
            d/tag: d/source1/value
            d/bitcount: 8   ;7
          ;  print-line ["in the if , the d/bitcount value is:"d/bitcount]
        ]
        
        ; print-line ["d/bitcount is :"d/bitcount]
        ;--shift bit out of tag--
        ;print-line "shift bit out of tag"
        j: d/tag
        ;print-line ["before shift d/tag is:"d/tag]
        d/tag: d/tag >> 1
       ; print-line ["after shift d/tag is:"d/tag]
        j and 00000001
      
        
    ]

    ;--read a num bit value from a stream and add base--
    read-bits: func [
        d [DATA! ]
        num [integer!]
        base [integer!]
        return: [integer!]
        /local
        i [integer!]
        val [integer!]
        limit [integer!]
        mask [integer!]
    ][ ;print-line "read-bits begin---------------------------------------"
        val: 0
      ; print-line ["num is:" num]
       ;print-line ["base is:"base]
    ;--read num bits--
    if num <> 0 [ 
        limit: 1 << num
       ; print-line ["limit is" limit]
        mask: 1
        until[
            i: getbit d
           ; print-line ["i:"i]
            if i <> 0 [
                val: val + mask
            ]
            mask: mask * 2
            mask >= limit
        ]
        


    ]
        val + base    ;return
    ]   

    ;--given a data stream and a tree,decode a symbol--
    decode-symbol: func [
        d [DATA! ]
        t [TREE! ]
         return: [integer!]
         /local
         sum [integer!]
         cur [integer!]
         len [integer!]
         i [integer!]
         j [integer!]
         l [integer!]
         

    ][  print-line "welcome to the decode-symbol"
        sum: 0
        cur: 0
        len: 1
        
        until[
            i: getbit d
            cur: 2 * cur + i
            ;print-line ["before (-j) the cur's value is:"cur]
            len: len + 1
           ; print-line "the cur's value 1"
            j: t/table/len
            ;print-line ["before (-j) cur's value is:"cur]
            sum: sum + j
            cur: cur - j
            ; print-line ["after (-j) cur's value is:"cur]
            ; print-line ["after (-j) sum's value is:"sum]
            ; print-line ["t/table/len's value is:"j]
            ; print-line ["len's value is :"len]
            cur < 0
        ]
        l: sum + cur + 1
       ; print-line ["t/trans/(sum+cur)'s value is: "t/trans/l]
        t/trans/l

    ]

    ;--given a data stream,decode dynamic trees from it--
    decode-trees: func [
       d [DATA! ]
       lt [TREE! ]
       dt [TREE! ]

       /local
       code-tree [TREE! value]
       
       lengths [int-ptr!] ;byte->int pointer
       
       hlit [integer!]
       hdist [integer!]
       hclen [integer!]

       i [integer!]
       num [integer!]
       length [integer!]

       clen [integer!]

       j [integer!]
       sym [integer!]

       prev [integer!]

       l [integer!]

    ][  
        init-TREE code-tree

        lengths: as int-ptr! allocate 1400
        ;--get 5 bits HLIT (257-286)--
        hlit: read-bits d 5 257
        print-line ["the hlit's value is:"hlit]

        ;--get 5 bits HDIST (1-32)
        hdist: read-bits d 5 1
        print-line ["the hdist's value is:"hdist]
        ;--get 4 bits HCLEN (4-19)--
        hclen: read-bits d 4 4
        print-line ["the hclen's value is:"hclen]
        i: 1
        until [
            lengths/i: 0
            i: i + 1
            i = 20
        ]

        ;--read code lengths for code lengte alphabet--
        i: 1
        until [
            ;--get 3 bits code length (0-7)--
            clen: read-bits d 3 0
            j: clcidx/i + 1
            lengths/j: clen
            ;print-line ["the lengths/j's value is :"lengths/j]
            i: i + 1
            i = (hclen + 1)

        ]
        ;--test--
        i: 1
        until [
            ; print-line ["the lengths/j's value is :"lengths/i]
             i: i + 1
             i = 20
        ]
         
        ;--test--
        print-line "the first time use the build-tree function"
        ;--build code length tree--
        build-tree code-tree lengths 19

        print-line "we have finished the first work~~~~~~~~~~`"

        ;--decode code lengths for the dynamic trees--
        num: 0
        until [
            sym: decode-symbol d code-tree
            print-line ["the sym's value is!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:"sym]
            switch sym[
                16 [
                    ;--copy previous code length 3-6 times (read 2 bits)--
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
                    ;--repeat code length 0 for 3-10 times (read 3 bits)--
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
                    ;--repeat code length 0 for 11-138 times (read 7 bits)--
                    length: read-bits d 7 11
                    print-line ["the length's value is:"length]
                     until [
                       print-line ["the num's value is:"num]
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
                print-line [" finish the first decompress"]
            num >= (hlit + hdist)
        ]
        
        print-line "we will build dynamic trees~~~~~~~~~~~~~~~~~~~~~~"
        ;--build dynamic trees--
        build-tree lt lengths hlit
        print-line "we have finished the first dynamic trees!!!!!!!"
        build-tree dt (lengths + hlit) hdist
        print-line "we have finished building dynamic trees~~~~~~~`"

    ]

;--------------------------
;--block inflate function--
;--------------------------

;--given a stream and two trees, inflate a block of data--
    inflate-block-data: func [
        d [DATA! ]
        lt [TREE! ]
        dt [TREE! ]
        return: [integer!]
        /local
        start [int-ptr! ]
        sym [integer!]

        length [integer!]
        dist [integer!]
        offs [integer!]
        i [integer!]

        j [integer!]
        l [integer!]
        k [integer!]
    ][
        ;start: as int-ptr! allocate 2000
        ;--remember current output position--
        ;print-line "start inflate-block-data"
        ;print-line d/bitcount
        start: d/dest
        l: 1
        until [
            sym: decode-symbol d lt
            ;print-line ["the symbol's value is:"sym]
            ;--check for end of block

            if sym = 256 [
                d/destLen/value: d/destLen/value + (d/dest - start)
                ;print-line "in the sym=256 's work 00000000000000000"
                break
            ]

            if sym < 256 [
                d/dest/value: sym
                d/dest: d/dest + 1
               ; print-line ["the sym's value is: "sym]
                ;print-line "in the sym<256 's work hhhhhhhhhhhhhhhh"
            ]

            if sym > 256 [
                sym: sym - 257  ;256 or 257
                k: sym + 1
                ;--possibly get more bits from length code--
               ; print-line "begin to get length'value"
               ; print-line ["the length-base/1'value is:"length-base/1 ]
               ; print-line [length-base/k]
                length: read-bits d length-bits/k length-base/k
               ; print-line ["length'value is:"length]
              ;  print-line "begin to get dist's value~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                dist: decode-symbol d dt
               ; print-line ["dist's value is:" dist]
                ;print-line "begin to get offs' value~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                ;--possibly get more bits from distance code--
                k: dist + 1
               ; print-line ["the dist-bits/k ' value is!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:"dist-bits/k]
               ; print-line ["the dist-base/k' value is:"dist-base/k]
                offs: read-bits d dist-bits/k dist-base/k
               ; print-line ["the offs' value is------------------------------------------------:" offs]

                ;--copy match--
                i: 1
                until[
                    j: i - offs
                    d/dest/i: d/dest/j
                    i: i + 1
                    i = (length + 1)
                ]
                
                d/dest: d/dest + length
                ;print-line "finished the 257 work~!!!!!!!!!!!!!!!!!!!1"

            ]
            l < 0
        ]
        0
        

    ] 


    ;--inflate an uncompressed block of data--
    inflate-uncompressed-block: func[
        d [DATA! ]
        return: [integer!]
        /local
        length [integer!]
        invlength [integer!]
        i [integer!]

        j [int-ptr!]
        l [int-ptr!]
    ][
        ;--get length--
        length: d/source1/2  ; c's d->source[1]
        length: 256 * length + d/source1/1

        ;--get one's complement of length--
        invlength: d/source1/4 ;c's d->source[3]
        invlength: 256 * invlength + d/source1/3

        ;--check length--
        
        d/source1: d/source1 + 4

        ;--copy block--
        i: length
        until [
            j: d/dest + 1
            l: d/source1 + 1
            j: l
            i: i - 1
            i = 0
        ]

        ;--make sure we start next block on a byte boundary--
        d/bitcount: 0
        d/destLen: d/destLen + length

        0;return ok
    ]

    ;--inflate a block of data compressed with fixed huffman trees--
    inflate-fixed-block: func [
            d [DATA! ]
            ;return [integer]
    ][
        inflate-block-data d sltree sdtree
    ]

    ;--inflate a block of data compressed with dynamic huffman trees--
    inflata-dynamic-block: func [
        d [DATA! ]
        ;return [integer]
    ][  init-TREE d/ltree
        init-TREE d/dtree
        ;--decode trees from stream--
        decode-trees d d/ltree d/dtree

        ;--decode block using decoded trees--
        inflate-block-data d d/ltree d/dtree        
    ]

;----------------------
;--public functions----
;----------------------
    
    ;--initialize global (static) data--
    init: func [][
        ;--build fixed huffman trees--
        print-line "build-fixed-trees  begin"
        build-fixed-trees sltree sdtree
        print-line "build fixed trees"
        ;--build extra bits and base tables--
        build-bits-base length-bits length-base 4 3 
        build-bits-base dist-bits dist-base 2 1
        print-line "build extra bits/base tables"
        
        ;--fix a special carse--
        length-bits/29: 0
        length-base/29: 258
        
    ]

    ;--inflate stream from source to dest--
    uncompress: func [
        dest [int-ptr!]  ;c's void * dest
        destLen [int-ptr!]
        source1 [int-ptr!]
        sourceLen [integer!]

        /local
        bfinal [integer!]
        d [DATA! value]

        btype [integer!]
        res [integer!]
    ][
        ;--initialise data--
        d/source1: source1
        d/bitcount: 1

        d/dest: dest
        d/destLen: destLen

        destLen/value: 0

        until [
            print-line "begin to decompress"
            ;--read final block flag--
            bfinal: getbit d
            print-line ["bifnal value is :"bfinal]
            ;--read block type (2 bits)--
            ;print-line ["outside the d/bitcount value is:"d/bitcount]
            ;print-line ["outside the d/tag value is:"d/tag]
            btype: read-bits d 2 0
            print-line ["block type is~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`:" btype]

            switch btype [
                0 [
                    ;--decompress uncompressed block--
                    res: inflate-uncompressed-block d
                    print-line "decompress uncompressed block"
                    break
                ]

                1 [
                    ;--decompress block with fixed huffman trees--
                    inflate-fixed-block d   ;return???
                    print-line "decompress block with fixed huffman trees"
                    break
                ]

                2 [
                    print-line "decompress block with dynamic huffman trees"
                    ;--decompress block with dynamic huffman trees--
                    inflata-dynamic-block d
                    break
                ]

                default [
                    print-line ["uncompressed is error"]
                    break
                ]
            ]
                    ;--if res!=ok return error
                    bfinal <> 0
        ]
         ;return ok
    ]

;----------------------
;----test function-----
;----------------------

#import [
    "zlib.dll" cdecl [
        compress: "compress" [
            dst [byte-ptr!]
            dstLen [int-ptr!]
            src [c-string!]
            srcLen [integer!]

            return: [integer!]
        ]
    ]
]
;--compress data
res: declare integer!
src: "today i am so happy, why? because i have finished the work. and tomorrow i will continue to gank the next task"
dst: as byte-ptr! allocate 1000000
dstLen: 1024
srcLen: declare integer!
srcLen: length? src
print-line [srcLen]
res: compress dst :dstLen src srcLen
print-line ["return :" res ]
print-line dstLen
i: 1
j: 0
until[
j: as integer! dst/i
;print-line ["return code:" j ]
i: i + 1
i = (dstLen + 1)
]

;--decompress dataq
print-line "1"
srcLen: dstLen
src1: as int-ptr! allocate 100000
i: 1
until [
    src1/i: as integer! dst/i
   print-line ["the src code is:" src1/i]
    i: i + 1
    i = (srcLen + 1)
]
print-line "2"
;src: as byte-ptr! dst
dst1: as int-ptr! allocate 100000
c: declare byte!
dstLen1: 1024
print-line "3"
init
src1: src1 + 1
srcLen: srcLen - 6
print-line "4"
print-line "uncompress begin"
uncompress dst1 :dstLen1 src1 srcLen
i: 1
until [
    c: as byte! dst1/i
    print [c]
    i: i + 1
    i = dstLen1
]




