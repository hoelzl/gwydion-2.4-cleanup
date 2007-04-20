rcs-header: $Header: /scm/cvs/src/d2c/runtime/dylan/weak.dylan,v 1.2 2000/01/24 04:56:50 andreas Exp $
copyright: see below
module: dylan-viscera

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
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

define class <weak-pointer> (<object>)
end;

define method make (class == <weak-pointer>,
		    #key object = required-keyword(object:))
  %%primitive(make-weak-pointer, object);
end;

define method weak-pointer-object (weak-ptr :: <weak-pointer>)
    => (object :: <object>, broken :: <boolean>);
  %%primitive(weak-pointer-object, weak-ptr);
end;



// Weak lists.

define class <weak-list> (<mutable-sequence>)
  slot contents :: <list>, required-init-keyword: contents:;
end;

define method make (class == <weak-list>, #key contents = $not-supplied,
		    size = $not-supplied, fill)
  if (contents == $not-supplied)
    next-method(class,
		contents: if (size == $not-supplied)
			    #();
			  else
			    make(<list>, size: size,
				 fill: make(<weak-pointer>, object: fill));
			  end);
  elseif (size == $not-supplied)
    next-method(class,
		contents:
		  map-as(<list>, curry(make, <weak-pointer>, object:)));
  else
    error("Can't supply both size: and contents: to make of <weak-list>");
  end;
end;

define method add (weak-list :: <weak-list>, element :: <object>)
    => res :: <weak-list>;
  make(<weak-list>, contents: pair(element, as(<list>, weak-list)));
end;

define method add! (weak-list :: <weak-list>, element :: <object>)
    => res :: <weak-list>;
  weak-list.contents := add!(make(<weak-pointer>, object: element),
			     weak-list.contents);
  weak-list;
end;

define method remove (weak-list :: <weak-list>, element :: <object>,
		      #key test = \==, count = $not-supplied)
  make(<weak-list>,
       contents: if (count == $not-supplied)
		   remove(as(<list>, weak-list), element, test: test);
		 else
		   remove(as(<list>, weak-list), element,
			  test: test, count: count);
		 end);
end;

define method remove! (weak-list :: <weak-list>, element :: <object>,
		       #key test = \==, count = $not-supplied)
  local method new-test (weak-ptr, element)
	  let (object, broken?) = weak-pointer-object(weak-ptr);
	  // We can't remove the broken ones because doing so would mess up
	  // the count.
	  ~broken? & test(object, element);
	end;
  weak-list.contents
    := if (count == $not-supplied)
	 remove!(weak-list.contents, element, test: new-test);
       else
	 remove!(weak-list.contents, element, test: new-test, count: count);
       end;
  weak-list;
end;

define method reverse (weak-list :: <weak-list>)
    => res :: <weak-list>;
  make(<weak-list>, contents: reverse(as(<list>, weak-list.contents)));
end;

define method reverse! (weak-list :: <weak-list>)
  weak-list.contents := reverse!(weak-list.contents);
end;


define method forward-iteration-protocol (weak-list :: <weak-list>)
  let list = as(<list>, weak-list);
  values(list,
	 #(),
	 tail,
	 \==,
	 method (weak-list, 
	 head,
	 head-setter,
	 identity);
end;
