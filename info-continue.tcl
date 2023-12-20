#!/usr/bin/env tclsh


for {set x 0} {$x<10} {incr x} {
                 if {$x == 5} {
                    continue
                 }
                 puts "x is $x"
              }
