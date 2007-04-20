Module:       Dylan-User
Synopsis:     DUIM concrete gadget panes, for GTK
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library gtk-duim-gadget-panes
  use dylan;

  use duim-utilities;
  use duim-geometry;
  use duim-DCs;
  use duim-sheets;
  use duim-graphics;  
  use duim-layouts;
  use duim-gadgets;
  use duim-frames;

  export duim-gadget-panes;
  export duim-gadget-panes-internals;
end library gtk-duim-gadget-panes;
