define load-app
    print "LOADING " $arg0
    set architecture arm
    set osabi GNU/Linux
    target remote 127.0.0.1:1234
    handle SIGILL nostop pass noprint
    add-symbol-file $arg0 0x40000000
end

define run
    conti
end