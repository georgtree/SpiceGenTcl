package require tcltest
namespace import ::tcltest::*
package require SpiceGenTcl
package require math::constants
namespace import ::tcltest::*
::math::constants::constants radtodeg degtorad pi
variable pi

set epsilon 1e-8

namespace import ::SpiceGenTcl::*

RawFile new "diode iv.raw" * ltspice
