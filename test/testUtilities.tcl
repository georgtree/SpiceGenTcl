proc testTemplate {testName descr createStr refStr} {
    test $testName $descr -body {
        if {[catch {set inst [{*}$createStr]} errorStr]} {
            return $errorStr
        }
        return [$inst genSPICEString]
    } -result $refStr
}
