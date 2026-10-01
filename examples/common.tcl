proc syncAxisGroup {members graph changedAxes} {
    global axesStates
    # Find which member changed independently.
    foreach member $members {
        lassign $member sourceGraph sourceAxis
        if {$sourceGraph ne $graph || $sourceAxis ni $changedAxes} {
            continue
        }
        if {$sourceAxis ni [$sourceGraph axis names]} {
            continue
        }
        lassign [$sourceGraph axis limits $sourceAxis] newMin newMax
        lassign [dict get $axesStates $sourceGraph $sourceAxis] oldMin oldMax
        if {($newMin == $oldMin) && ($newMax == $oldMax)} {
            continue
        }
        dict set axesStates $sourceGraph $sourceAxis [list $newMin $newMax]
        set oldSpan [expr {$oldMax-$oldMin}]
        if {$oldSpan == 0} {
            return
        }
        # Relative movement of each endpoint.
        set leftShift  [expr {($newMin-$oldMin)/double($oldSpan)}]
        set rightShift [expr {($newMax-$oldMax)/double($oldSpan)}]
        foreach target $members {
            lassign $target targetGraph targetAxis
            if {$targetGraph eq $sourceGraph && $targetAxis eq $sourceAxis} {
                continue
            }
            if {$targetAxis ni [$targetGraph axis names]} {
                continue
            }
            lassign [$targetGraph axis limits $targetAxis] lo hi
            set span [expr {$hi - $lo}]
            set targetMin [expr {$lo+$leftShift*$span}]
            set targetMax [expr {$hi+$rightShift*$span}]
            if {($targetMin != $lo) || ($targetMax != $hi)} {
                $targetGraph axis configure $targetAxis -min $targetMin -max $targetMax
            }
            dict set axesStates $targetGraph $targetAxis [$targetGraph axis limits $targetAxis]
        }
        return
    }
}

proc syncAxes {graph axes masterAxis slaveGraph slaveAxis} {
    if {($masterAxis ni $axes) || ($masterAxis ni [$graph axis names]) ||\
                ($slaveAxis ni [$slaveGraph axis names])} {
        return
    }
    lassign [$graph axis limits $masterAxis] newMin newMax
    lassign [dict get $::axesStates $graph $masterAxis] oldMin oldMax
    # ignore notifications for limits we have already processed.
    if {($newMin==$oldMin) && ($newMax==$oldMax)} {
        return
    }
    dict set ::axesStates $graph $masterAxis [list $newMin $newMax]
    set oldSpan [expr {$oldMax-$oldMin}]
    if {$oldSpan==0} {
        return
    }
    lassign [$slaveGraph axis limits $slaveAxis] slaveMin slaveMax
    set scale [expr {($slaveMax-$slaveMin)/double($oldSpan)}]
    set targetMin [expr {$slaveMin+($newMin-$oldMin)*$scale}]
    set targetMax [expr {$slaveMax+($newMax-$oldMax)*$scale}]
    if {($targetMin != $slaveMin) || ($targetMax != $slaveMax)} {
        $slaveGraph axis configure $slaveAxis -min $targetMin -max $targetMax
    }
    # record the actual resulting limits, including any RBC adjustments.
    # The slave's subsequent event therefore causes no reverse update.
    dict set ::axesStates $slaveGraph $slaveAxis [$slaveGraph axis limits $slaveAxis]
}

set colors {#5470c6 #91cc75 #fac858 #ee6666 #73c0de #3ba272 #fc8452 #9a60b4 #ea7ccc}
