/**********************************************************************\
*
*  Copyright (c) 1994  Carnegie Mellon University
*  Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
*  All rights reserved.
*  
*  Use and copying of this software and preparation of derivative
*  works based on this software are permitted, including commercial
*  use, provided that the following conditions are observed:
*  
*  1. This copyright notice must be retained in full on any copies
*     and on appropriate parts of any derivative works.
*  2. Documentation (paper or online) accompanying any system that
*     incorporates this software, or any part of it, must acknowledge
*     the contribution of the Gwydion Project at Carnegie Mellon
*     University, and the Gwydion Dylan Maintainers.
*  
*  This software is made available "as is".  Neither the authors nor
*  Carnegie Mellon University make any warranty about the software,
*  its performance, or its conformity to any specification.
*  
*  Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
*  comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
*  Also, see http://www.gwydiondylan.org/ for updates and documentation. 
*
***********************************************************************
*
* $Header: /scm/cvs/src/mindy/interp/obj.c,v 1.2 2000/01/24 04:58:20 andreas Exp $
*
* This file contains <object>.
*
\**********************************************************************/

#include "../compat/std-c.h"

#include "mindy.h"
#include "class.h"
#include "bool.h"
#include "list.h"
#include "def.h"
#include "gc.h"
#include "num.h"
#include "obj.h"

obj_t obj_ObjectClass = 0;

static obj_t dylan_object_class(obj_t object)
{
    return object_class(object);
}

static obj_t dylan_object_address(obj_t object)
{
    return make_bignum((long)object);
}


/* Init stuff. */

void make_obj_classes(void)
{
    obj_ObjectClass = make_abstract_class(FALSE);
    add_constant_root(&obj_ObjectClass);
}

void init_obj_classes(void)
{
    init_builtin_class(obj_ObjectClass, "<object>", NULL);
}

void init_obj_functions(void)
{
    define_function("object-class", list1(obj_ObjectClass), FALSE, obj_False,
		    FALSE, obj_ClassClass, dylan_object_class);
    define_function("object-address", list1(obj_ObjectClass), FALSE, obj_False,
		    FALSE, obj_FixnumClass, dylan_object_address);
}
