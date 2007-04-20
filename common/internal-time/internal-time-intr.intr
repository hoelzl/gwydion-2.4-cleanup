module: Internal-Time-Interface
author: Ben Folk-Williams
synopsis: A simple interface for calling some c time routines.
copyright: see below
//
// Copyright (c) 1996  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

// ### This whole library is ridiculously unportable, and because it's
// also not all that important, we're abandoning it.  This particular
// file works on HPs, and probably nothing else.

define constant <internal-time> = <integer>;

define interface
  #include "/usr/include/sys/times.h",
    object-file: "/lib/libc.sl",
    import: {"times"},
    name-mapper: minimal-name-mapping,
    rename: {"struct tms" => <tms>},
    map: {"clock_t" => <internal-time>};
  function "times",
    map-result: <internal-time>,
    output-argument: 1;
end interface;

define interface
  #include "/usr/include/unistd.h",
    object-file: "/lib/libc.sl",
    import: {"sysconf", "_SC_CLK_TCK"},
    name-mapper: minimal-name-mapping,
    rename: {"_SC_CLK_TCK" => $SC-CLK-TCK};
end interface;

