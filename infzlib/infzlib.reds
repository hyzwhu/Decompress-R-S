Red/System[]
#include %inflate.reds
#include %adler32.reds
    zlib-uncompress: func[
        dest        [byte-ptr!]
        destLen     [int-ptr!]
        source      [byte-ptr!]
        sourceLen   [integer!]
        return:     [integer!]
        /local
            src     [byte-ptr!]
            dst     [byte-ptr!]
            a32     [integer!]
            cmf     [byte!]
            flg     [byte!]
            a       [integer!]
            b       [integer!]
            c       [integer!]
            res     [integer!]
    ][  
        src: as byte-ptr! system/stack/allocate 1000
        dst: as byte-ptr! system/stack/allocate 1000
        src: source
        dst: dest
        ;--get header bytes
        cmf: src/1
        flg: src/2
        ;--check format
        ;--check checksum
        a: as integer! cmf
        b: as integer! flg
        if ((256 * a + flg) % 31) <> 0 [
            return -3
        ]
        ;--check method is deflate
        if (a and 0Fh) <> 8 [
            return -3
        ]
        ;--check window size is valid
        if (a >> 4) > 7 [
            return -3
        ]
        ;--check there is no preset dictionary
        if (b and 20h) <> 0 [
            return -3
        ]
        ;--get adler32 checksum
        b: sourceLen - 3
        a32: as integer! src/b
        b: sourceLen - 2
        a: as integer! src/b
        a32: 256 * a32 + a
        b: sourceLen - 1
        a: as integer! src/b        
        a32: 256 * a32 + a
        b: sourceLen 
        a: as integer! src/b        
        a32: 256 * a32 + a   
        ;--inflate
        res: uncompress dst destLen (src + 1) (sourceLen - 6)    
        if res <> 0 [
            return -3
        ]
        c: inf-adler32 dst destLen/value
        ;--chcek adler32 checksum
        if a32 <> c [
            return -3
        ]
        return 0
    ]
