module:		html
Author:		Robert Stockton (rgs@cs.cmu.edu)
synopsis:	Converts a file in WWW "HyperText Markup Language" into
                formatted text.  Provides a small demo of a 'complete
		application' in Dylan.

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
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

//======================================================================
// This program is a filter which converts text in WWWs "HyperText Markup
// Language" into simple formatted text.  Although it is a complete and useful
// application, it is included in this distribution primarily as a
// demonstration of a "real" (albeit small) Dylan (tm) program.
//
// Usage is typical for a UNIX (tm) program.  It may be invoked either with a
// set of files on the command line:
//   mindy -f html2txt.dbc file1.html file2.html ....
// or with no arguments, in which case it reads from "standard input".  At
// present, it accepts no command line switches, although the behavior may be
// changed by changing several constant declarations towards the top of this
// source file.
//
// On most unix systems you should be able to make it into an executable
// script by prepending the the line
//   #!BINDIR/mindy -f
// to the compiled "dbc" file.  You must, of course, remember to specify the
// MINDYPATH environment variable so that it points to the libraries "dylan",
// "streams", "collection-extensions", and "string-extensions".
//
// The basic translation strategy used by html2txt is to scan the file line by
// line, looking for HTML "tags" and accumulating text that lies between any
// two tags.  For each tag type, there is a set of routines (stored in tables)
// which define the appropriate actions for starting and ending the
// "environment" defined by the tag and for dumping the collected text from
// within that environment as formatted text.  A basic control loop in
// "process-HTML" is responsible for calling the appropriate tag actions.
// This routine may be called recusively by some of the tag actions.
//
// The "interface" between adjacent environments is handled via the "blank"
// parameter which is passed around extensively.  This variable states whether
// a blank line has just been printed.  Thus environments which believe that
// they must be preceded or followed by a blank line can determine whetehr
// they must do anything about it, and we lessen the risk that multiple
// routines will emit blank lines when we only want a maximum of one.
//
// The primary advantage of this organization is that it allows the
// specialized actions for a single tag to be grouped together, and allows new
// tags to be cleanly added.  It benefits greatly from Dylan's ability to
// create anonymous methods and manipulate them as first class data objects,
// as well as from the rich set of available collection types.
//======================================================================

define generic html2text(input) => ();

define constant normal-font = "-adobe-courier-medium-r-normal--12*";
define constant H1-font = "-adobe-courier-bold-r-normal--12*";

define constant text-frame
  = make(<frame>, height: 500, fill: "both", side: "bottom", expand: #t);
define constant text-window
  = make(<text>, in: text-frame, relief: "sunken", font: normal-font,
	 fill: "both", side: "right", expand: #t);
define constant end-mark = make(<text-mark>, in: text-window, name: "end");
define constant bold-tag = make(<text-tag>, font: H1-font, 
				in: text-window);

// This will eliminate the text window's built-in tendency to encourage text
// editing and entry.  It's probably best to simply consider it black magic
// rather than expecting it to make sense.
bind(text-window, "<Button-1>", "%W mark set anchor @%x,%y;focus none");

define constant text-scroll
  = scroll(text-window, in: text-frame, fill: "y");

define method tell-about()
  let top = make(<toplevel>, name: "information");
  unmap-window(top);
  Make(<Message>, In: Top, Aspect: 300, relief: "raised", borderwidth: 1,
           Text: "Html2Text is a demonstration application which converts "
             "text in the hypertext markup language into simple formatted "
             "ascii.\n\nThe primary purpose of this application, however, "
             "is to demonstrate the feasibility of adding windowed "
             "interfaces to a Mindy program.",
       side: "top", fill: "both", pady: "3m");
  let frame = make(<frame>, in: top, fill: "both", relief: "raised",
		   borderwidth: 1, expand: #t); 
  make(<button>, in: frame, text: "Okay", expand: #t, relief: "raised",
       command: curry(destroy-window, top), pady: "3m");
  map-window(top);
end method tell-about;

define variable *input-file* = #t;
define variable *H1cap* 
  = make(<active-variable>, class: <boolean>, value: #f);
define variable *H1under*
  = make(<active-variable>, class: <boolean>, value: #t);
define variable *H2cap*
  = make(<active-variable>, class: <boolean>, value: #f);
define variable *H2under*
  = make(<active-variable>, class: <boolean>, value: #t);
define variable *Bcap*
  = make(<active-variable>, class: <boolean>, value: #t);
define variable *Icap*
  = make(<active-variable>, class: <boolean>, value: #t);

define constant menu-frame
  = make(<frame>, relief: "raised", fill: "x", side: "top", borderwidth: 2);

define constant status-variable = make(<active-variable>, class: <symbol>,
				       value: #"idle");

define constant file-button
  = make(<menubutton>, text: "Files", in: menu-frame);
define constant file-menu
  = make(<menu>, in: file-button);
add-command(file-menu, label: "About html2txt", command: tell-about);
add-separator(file-menu);
add-command(file-menu, label: "Recompute",
	    command: method ()
		       spawn-thread("recomp", curry(html2text, *input-file*))
		     end method);
add-command(file-menu, label: "Quit", command: "exit");
configure(file-button, menu: file-menu);

define constant var-button
  = make(<menubutton>, text: "Variables", in: menu-frame);
define constant var-menu
  = make(<menu>, in: var-button);
add-checkbutton(var-menu, label: "Capitalize <H1> headers", variable: *H1cap*);
add-checkbutton(var-menu, label: "Underline <H1> headers",variable: *H1under*);
add-separator(var-menu);
add-checkbutton(var-menu, label: "Capitalize <H2> headers", variable: *H2cap*);
add-checkbutton(var-menu, label: "Underline <H2> headers",variable: *H2under*);
add-separator(var-menu);
add-checkbutton(var-menu, label: "Capitalize <B> strings", variable: *Bcap*);
add-checkbutton(var-menu, label: "Capitalize <I> strings", variable: *Icap*);
configure(var-button, menu: var-menu);

define constant status-label =
  make(<label>, relief: "sunken", textvariable: status-variable,
       width: 20, in: menu-frame, side: "right");
       

define constant entry-frame
  = make(<frame>, relief: "groove", fill: "x", side: "top", borderwidth: 2);

define constant length-variable = make(<active-variable>, class: <integer>,
				       value: 78);
define constant margin-variable = make(<active-variable>, class: <integer>,
				       value: 2);
define constant file-variable = make(<active-variable>, value: "");

define method check-restart()
  if (length-variable.value ~= *linelen* | margin-variable.value ~= *margin*
	| file-variable.value ~= *input-file*)
    *input-file* := file-variable.value;
    spawn-thread("recomp", curry(html2text, *input-file*));
  end if;
end method check-restart;

define method value-entry(prompt, variable, width, #key expand = #f)
  let label = make(<label>, in: entry-frame, text: prompt,
		   side: "left"); 
  let entry = make(<entry>, in: entry-frame, width: width,
		   relief: "sunken", textvariable: variable,
		   side: "left", expand: expand,
		   fill: if (expand) "x" else "none" end if);
  bind(entry, "<Return>", check-restart);
end method value-entry;

value-entry("Input file: ", file-variable, 20, expand: #t);
value-entry("Line length: ", length-variable, 4);
value-entry("Margin: ", margin-variable, 4);

// Trivial main program -- just invokes "html2text" which in turn invokes
// "process-HTML".  Note that we had to import the generic function "main"
// from module "extensions" in library "dylan".  This interface is Mindy
// specific.
define method main (argv0, #rest args) => ();
  if (empty?(args))
    *input-file* := #t;
  else
    file-variable.value := *input-file* := args.first;
  end if;

  map-window(*root-window*);
  spawn-thread("html2text", method () html2text(*input-file*) end method);

  block (return)
    while (#t)
      let input = read-line(*standard-input*);
      if (input = "quit")
	return();
      elseif (input = "break")
	break();
      else
	put-tk-line(as(<string>, input))
      end if;
    end while;
  end block;
  put-tk-line("exit");
end method main;

// Basic constants
define constant <strings> = <stretchy-vector>;
define variable *linelen* :: <integer> = 78;
define variable *margin* :: <integer> = 2;

// Internal constants
define variable Pre-Count :: <integer> = 0;
define variable prefix :: <string> = "";
define variable counter :: <integer> = 0;

// We can use hash tables for looking up tag processing routines, but "self
// organizing lists" tend to provide better performance in this case.  Since
// they are completely interchangeable, you can try switching the definition
// here to swap in the "standard" table support instead.

define constant <tag-table> = <self-organizing-list>;
// define constant <tag-table> = <object-table>;


//////////////////////////////////////////////////////////////////////////
//			       Window Streams				//
//////////////////////////////////////////////////////////////////////////
define class <window-stream> (<buffered-stream>)
  slot window :: <text>, required-init-keyword: #"window";
  slot buffer :: <buffer>;
end class <window-stream>;

define method stream-open? (stream :: <window-stream>)
 => open? :: singleton(#t);
  #t;
end method stream-open?;

define method stream-element-type (stream :: <window-stream>)
 => type :: singleton(<byte-character>);
  <byte-character>;
end method stream-element-type;

define method stream-at-end? (stream :: <window-stream>)
 => at-end? :: singleton(#f);
  #f;
end method stream-at-end?;

define method initialize
    (object :: <window-stream>, #next next, #key size = 256, #all-keys);
  object.buffer := make(<buffer>, size: size, end: size);
end method initialize;

define method close (stream :: <window-stream>, #key, #all-keys) => ();
  #f;
end method close;

define method do-get-output-buffer (stream :: <window-stream>,
				    #key bytes :: <integer> = 1)
 => buffer :: <buffer>;
  let buff :: <buffer> = stream.buffer;
  if (buff.size < bytes)
    error("Can't possibly get %d bytes -- %=", bytes, stream);
  elseif ((buff.buffer-end - buff.buffer-next) < bytes)
    do-force-output-buffers(stream);
  end;  
  buff;
end method do-get-output-buffer;

define constant newline-value = as(<integer>, '\n');
define method do-release-output-buffer (stream :: <window-stream>)
 => ();
// The commented code provides "eager" behavior -- i.e. it forces output after
// newlines.  This is useful, but probably not worth the cost, especially
// since we already have explicit "force"s in place.
  let buff = stream.buffer;
  let next = buff.buffer-next;
  for (i from next - 1 to 0 by -1, until: buff[i] == newline-value)
  finally
    if (i >= 0)
//       ERROR: fails if result-class is anything other than <byte-string>
      let extra = buffer-subsequence(buff, <byte-string>, i + 1, next);
      insert(stream.window, "end",
	     buffer-subsequence(buff, <byte-string>, 0, i + 1));
      copy-into-buffer!(buff, 0, extra);
      buff.buffer-next := extra.size;
    else
      #f;
    end if;
  end for;
end method do-release-output-buffer;

define method do-next-output-buffer (stream :: <window-stream>,
				     #key bytes :: <integer> = 1)
 => buf :: <buffer>;
  let buff :: <buffer> = stream.buffer;
  if (buff.size < bytes)
    error("Can't possibly get %d bytes -- %=", bytes, stream);
  elseif ((buff.buffer-end - buff.buffer-next) < bytes)
    do-force-output-buffers(stream);
  end;
  buff;
end method do-next-output-buffer;

define method do-force-output-buffers (stream :: <window-stream>)
 => ();
  let buff = stream.buffer;
  let last = buff.buffer-next;
  insert(stream.window, "end",
	 buffer-subsequence(buff, <byte-string>, 0, last));
  if (last ~= buff.size)
    let extra = buffer-subsequence(buff, <byte-string>, last, buff.size);
    copy-into-buffer!(buff, 0, extra);
    buff.buffer-next := extra.size;
  else
    buff.buffer-next := 0;
  end if;
end method do-force-output-buffers;

define method do-synchronize (stream :: <window-stream>) => ();
end method do-synchronize;

define constant *window-stream* = make(<window-stream>, window: text-window);
define constant html-status-lock = make(<lock>);
define variable html-status :: <symbol> = #"idle";
define constant html-restart-event = make(<event>);


//////////////////////////////////////////////////////////////////////////
//			       String Utilities				//
//////////////////////////////////////////////////////////////////////////

// Find the index of first element (after "from") of a sequence which
// satisfies the given predicate.  (Like find-key, but guaranteed sequential
// and accepts start: and end: rather than skip:.)

// This program makes heavy use of start: and end: keywords (in order to avoid
// copying subsequences).  Find-key would have been completely unsuitable for
// this unless we used <subsequence>s to refer to slices of existing
// sequences, and even then the efficiency penalty would have been high.  It
// therefore seemed better to simply define new routines to do "the right
// thing". 
define method sfind(seq :: <sequence>, pred?, 
		    #key start: start = 0,
		         end: last, failure: fail)
  block (return)
    let last = if (last) min(last, size(seq)) else size(seq) end if;
    for (i :: <integer> from start below last)
      if (pred?(seq[i])) return(i)  end if;
    finally 
      fail;
    end for;
  end block;
end method sfind;

// Like sfind, but goes backward from the end (or from before end:).
define method rsfind(seq :: <sequence>, pred?,
		     #key start: start = 0,
		          end: last, failure: fail)
  block (return)  
    let last = if (last) min(last, size(seq)) else size(seq) end if;
    for (i from last - 1 to start by -1) 
      if (pred?(seq[i])) return(i)  end if;
    finally 
      fail;
    end for;
  end block;
end method rsfind;

// The notation "'!' * 5" is a good way to create a string of repeated
// characters.  This variety of overloaing is becoming popular in several
// modern languages (i.e. C++, Perl, and Ada).
define method \*(ch :: <character>,
		 times :: <integer>)  => (result :: <byte-string>);
  make(<byte-string>, size: times, fill: ch) 
end method \*;

////////////////////////////////////////////////////////////////////////
//			     Basic HTML Utilities		      //
////////////////////////////////////////////////////////////////////////

// Simply a conventient shorthand for writing to *window-stream*.
define method write-string(string :: <string>)
  if (html-status == #"aborting")
    abort();
  end if;
  write(*window-stream*, string);
end method write-string;

// Print a line according to *margin* and *linelen*.  Add special handling for
// *prefix* hack.  Streams don't automatically flush output at the ends of
// lines, so we flush the output ourselves to allow the output to be viewed
// interactively. 
define method print-with-prefix(str :: <string>, #rest args) 
  for (i from 1 to *margin* - size(prefix))
    write(*window-stream*, " ");
  end for;
  write-string(prefix); 
  apply(write-line, *window-stream*, str, args);
  prefix := "" ;
  force-output(*window-stream*);
end method print-with-prefix;

// As mentioned above, "tag action routines" are stored in tables for easy
// reference.  They are keyed by symbols corresponding to the tag (i.e.
// #"text"). 
define constant add-text-table :: <tag-table> = make(<tag-table>);

// The heavy duty search and replace operations in "add-text" are in the
// critical path, so it is worth optimizing these by pre-computing the search
// tables.  For more details, look at the "string-search" module in
// "extensions". 
define constant tab-to-space
  = make-substring-replacer("\t", replace-with: " ");
define constant convert-lt
  = make-substring-replacer("&lt;", replace-with: "<");
define constant convert-gt
  = make-substring-replacer("&gt;", replace-with: ">");
define constant convert-amp
  = make-substring-replacer("&amp;", replace-with: "&");

// Accumulates text within a single tag environment.  The appropriate tag
// action routine is called to transform the given text.  This may be
// "identity", "as-uppercase", or any other arbitrary action.
// This routine also transforms "quoted characters" (such as "&lt;" for '<')
// into their ascii equivalents and crunches tabs down into spaces.
define method add-text(tag :: <symbol>, text :: <strings>,
		       new-text :: <string>) => (result :: <strings>);
  // replace-substring only works on <byte-string>s.
  let new-text :: <string> =
    as(<byte-string>, new-text);
  let Tab-Free :: <string> =
    if (Pre-Count = 0)
      tab-to-space(new-text);
    else
      new-text;
    end if;
  let AMP :: <string> = convert-amp(convert-lt(convert-gt(Tab-Free)));
  
  let new-text = element(add-text-table, tag, default: identity)(AMP);
  
  if (empty?(new-text)) text else add!(text, new-text) end;
end method add-text;

// Special processing is required when newlines are encountered in the input
// stream.  If we are in a "<PRE>" environment, then we simply include a
// newline in the output.  If we are in any other environment, we must guess
// the correct number of spaces to put in based upon the punctuation of the
// previous line.
define method add-eol(text :: <strings>) => (result :: <strings>);
  if (Pre-Count > 0) 
    add!(text, "\n") 
  else
    let Prev-Str = last(text, default: "");
    if (Prev-Str.empty?)
      text;
    else
      let space = 
	select (Prev-Str.last)
	  '.', ':', '!', '?' =>
	    "  ";
	  '-', ' ' =>
	    "";
	  otherwise =>
	    " ";
	end select;
      add!(text, space);
    end if;
  end if 
end method add-eol;

// The "break-up" routines produce and print appropriate formatted text from
// the accumulated data.  The action defaults to the #"text" action, which
// breaks the text into lines (at word boundaries)according to the defined
// margins.  "break-up" then clears the accumulated text before returning
// control to the main loop.
define constant break-up-table :: <tag-table> = make(<tag-table>);
define method break-up(tag :: <symbol>, text :: <strings>, 
		       blank :: <boolean>,
		       want-blank :: <boolean>) => (result :: <boolean>);
  let full-text = if (text.empty?) "" else apply(concatenate, text) end;
  block ()
    break-up-table[tag](full-text, blank, want-blank);
//  exception (<error>)
//    break-up-table[#"TEXT"](full-text, blank, want-blank);
  cleanup
    size(text) := 0;
  end block;
end method break-up;

//add-method(signal, method (str :: <string>, #rest args)
//		     apply(format, *standard-error*, str, args);
//		   end method);

// Tag close defines the appropriate action to take at the end of an
// environment (i.e. when encountering "</PRE>".  This may be a null action,
// or may call "break-up" to dump the accumulated text, or may perform any
// other arbitrary action.
define constant tag-close-table :: <tag-table> = make(<tag-table>);
define method tag-close(tag :: <symbol>, close :: <symbol>,
			text :: <strings>, blank :: <boolean>)
    => (result :: <boolean>);
  if (tag ~= close) 
    #f;
//    signal(concatenate("Tag mismatch: <", as(<string>, tag), "> vs. </",
//		       as(<string>, close), ">.\n"))  
  end if;
  block ()
    tag-close-table[tag](tag, text, blank);
//  exception (<error>)
//    tag-close-table[#"TEXT"](tag, text, blank);
  end block;
end method tag-close;

// Tag start defines the appropriate action to take at the beginning of an
// environment (i.e. when encountering "<PRE>".  This may be a null action,
// or may call "break-up" to dump the accumulated text, or may perform any
// other arbitrary action.
define constant tag-start-table :: <tag-table> = make(<tag-table>);
define method tag-start(New-Tag :: <symbol>, Old-Tag :: <symbol>,
			Out-Text :: <strings>, Current-Text :: <string>, 
			File :: <stream>, blank :: <boolean>)
    => (New-Text :: <string>, blank :: <boolean>);
  let fun = block ()
	      tag-start-table[New-Tag];
//	    exception (<error>)
//	      signal("Unknown tag type: <%=>\n", New-Tag);
//	      tag-start-table[#"TEXT"];
	    end block;
  fun(New-Tag, Old-Tag, Out-Text, Current-Text, File, Blank);
end method tag-start;

// This routine is called at "load time" to build the tag action tables.  Note
// that "reasonable" defaults are defined for all actions so that only the
// "specialized" actions for any given environment need be specified.
define method add-tag(tags :: <sequence>,
		      #key add-text: AT = identity,
		           break-up: BU = break-up-table[#"TEXT"],
		           tag-close: TC = tag-close-table[#"TEXT"],
		           tag-start: TS = tag-start-table[#"TEXT"])
  for (tag in tags)
    let Tag-Symbol = as(<symbol>, tag);
    add-text-table[Tag-Symbol] := AT;
    break-up-table[Tag-Symbol] := BU;
    tag-close-table[Tag-Symbol] := TC;
    tag-start-table[Tag-Symbol] := TS;
  end for;
end method add-tag;

////////////////////////////////////////////////////////////////////////
//			     Main Driver Routines		      //
////////////////////////////////////////////////////////////////////////

// This is the workhorse routines.  It reads in new data, searches for tags,
// and dispatches the appropriate "add-text", "tag-start", and "tag-close"
// routines.  It also attempts to unwind gracefully when it encounters the end
// of the file, since many HTML data files fail to terminate all environments.
define method process-HTML(Tag :: <symbol>, Out-Text :: <strings>, 
			   Current-Text :: <string>, File :: <stream>,
			   blank :: <boolean>)
    => (Current-Text :: <string>, blank :: <boolean>);
  
  local method is-space(ch) ch == ' ' | ch == '\t' end method;
  local method tag-end(ch) ch == ' ' | ch == '\t' | ch == '>' end method;
  local method not-space(ch) ch ~= ' ' & ch ~= '\t' end method;
  
  block (return)
    while (#t)
      // keep crunching until EOF causes us to call "return"
      let Start-Tag = sfind(Current-Text, curry(\==, '<'));
      if (Start-Tag)
	// There is a tag on this line, so we accumulate the text which
	// precedes it and then invoke the appropriate tag actions.
	Out-Text := add-text(Tag, Out-Text,
			     subsequence(Current-Text, end: Start-Tag));
	
	// If a newline occurs within a tag, we must keep reading until we get
	// the rest of the tag.  Whitespace is simply used as a separator, so
	// we substitute a space for the newline.
	let End-Tag =
	  for (index = sfind(Current-Text, curry(\==, '>'), start: Start-Tag)
		 then sfind(Current-Text, curry(\==, '>'), start: Start-Tag),
	       until: index)
	    Current-Text := concatenate(Current-Text, " ", read-line(File));
	  finally index;
	  end for;
	
	// Find the complete tag and figure out whether it is "opening" or
	// "closing" an environment.
	let first = sfind(Current-Text, not-space, start: Start-Tag + 1);
	let Is-Close = Current-Text[first] = '/'; 
	if (Is-Close)
	  first := sfind(Current-Text, not-space, start: first + 1)
	end if; 
	let New-Tag =
	  as(<symbol>, copy-sequence(Current-Text, start: first, 
				     end: sfind(Current-Text, tag-end,
						start: first)));
	// Call the appropriate action for the tag.  This may invoke
	// a recursive call to "process-HTML" for start tags and will exit
	// this recusive call for closing tags.
	Current-Text := copy-sequence(Current-Text, start: End-Tag + 1);
	if (Is-Close)
	  return(Current-Text, tag-close(Tag, New-Tag, Out-Text, blank));
	else 
	  let (New-Text, NewBlank) = 
	    tag-start(New-Tag, Tag, Out-Text, Current-Text, File, blank);
	  Current-Text := New-Text;
	  blank := NewBlank; 
	end if;
      else
	// Process newlines.  We ignore indentation in the next line unless we
	// are inside a "<PRE>" environment.
	Out-Text := add-eol(add-text(Tag, Out-Text, Current-Text));
	let (New-Text, newline?) = read-line(File);
	let First-Real = if (Pre-Count = 0)
			   sfind(New-Text, not-space, failure: 0);
			 else 0
			 end if;
	Current-Text := if (First-Real > 0)
			  copy-sequence(New-Text, start: First-Real);
			else
			  New-Text;
			end if;
      end if;
    end while;
  exception (<end-of-stream-error>)
    // End of file processing.  Dump accumulated text and then exit.
    let blank = break-up(Tag, Out-Text, blank, #f);
    values("", blank);
  end block 
end method process-HTML;

// specialized routines to open various sourts of streams and invoke
// "process-HTML".
define method html2text(fd :: <stream>) => ();
  grab-lock(html-status-lock);
  while (html-status ~= #"idle")
    status-variable.value := #"aborting";
    html-status := #"aborting";
    wait-for-event(html-restart-event, html-status-lock);
    grab-lock(html-status-lock);
    // Just in case someone else stepped in ahead of us.
  end while;
  status-variable.value := #"active";
  html-status := #"active";
  release-lock(html-status-lock);
    
  delete(text-window, "1.0", end: "end");
  *linelen* := length-variable.value;
  configure(text-window, width: *linelen*);
  *margin* := margin-variable.value;
  pre-count := 0;
  prefix := "";

  block ()
    process-HTML(#"TEXT", make(<strings>), "", fd, #t);
  exception (<abort>)
    #f;
  cleanup
    force-output(*window-stream*);
  end block;

  grab-lock(html-status-lock);
  broadcast-event(html-restart-event);
  status-variable.value := #"idle";
  html-status := #"idle";
  release-lock(html-status-lock);
end method html2text;

define method html2text(file :: <string>) => ();
  let stream = make(<file-stream>, locator: file);
  html2text(stream);
  close(stream);
end method html2text;

define method html2text(file == #t) => ();
  html2text(make(<fd-stream>, fd: 0));
end method html2text;


////////////////////////////////////////////////////////////////////////
//			Specific Environment Routines		      //
////////////////////////////////////////////////////////////////////////

// The anonymous methods here implement the appropriate tag actions for all of
// the tags currently supported.  Some are quite straightforward, while others
// may require a twisted mind to "properly appreciate" them.  This
// organization does, at least, allow the processing of most tags to be
// isolated so that you needn't grok all the code at once.

add-tag(#["TEXT"],       	// Default environment
	// Performs a "paragraph break" and recursively processes the new
	// environment
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>, 
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     let blank = break-up(Old-Tag, Out-Text, blank, #t);
		     process-HTML(New-Tag, Out-Text, Current-Text,
				  File, blank);
		   end method,
	// Performs a "paragraph break" and returns to the enclosing
	// environment
	tag-close: method (tag :: <symbol>, text :: <strings>,
			   blank :: <boolean>) => (result :: <boolean>);
		     break-up(tag, text, blank, #t);
		   end method,
	// Breaks "text" into lines according to *margin* and *linelen*.
	// Parameters blank and want-blank say whether there is a blank line
	// before the current text and whether there should be one after the
	// current text.  The return value tells whether a blank line was
	// printed.
	break-up: method (text :: <string>, blank :: <boolean>, 
			  want-blank :: <boolean>)  => (result :: <boolean>);
		    let first = sfind(text, curry(\~=, ' ')); 
		    if (~first) 
		      if (want-blank & ~blank) write-string("\n")  end if;
		      blank | want-blank 
		    else
		      let Text-Size = size(text);
		      let Find-Break = 
			method (first, last)
			  if (last >= Text-Size)
			    Text-Size;
			  else 
			    let find = rsfind(text, curry(\=, ' '),
					      start: first, end: last); 
			    if (find)   
			      rsfind(text, curry(\~=, ' '), 
				     start: first, end: find) + 1 
			    else 
			      sfind(text, curry(\=, ' '), start: first)
				| size(text)
			    end if
			  end if
			end method; 
		      while (first)
			let last = Find-Break(first,
					      first + *linelen* - *margin*);
			print-with-prefix(text, start: first, end: last); 
			first := sfind(text, curry(\~=, ' '), start: last + 1)
		      end while; 
		      if (want-blank) write-string("\n")  end if; 
		      want-blank 
		    end if 
		  end method);

// This tag action is used for many different tags -- it simply invokes
// "process-HTML" recursively without doing anything special to the
// accumulated text.  This is handy for "lightweight" enviromentents like
// "<I>". 
define constant tag-start-recurse =
  method (New-Tag :: <symbol>, Old-Tag :: <symbol>, 
	  Out-Text :: <strings>, Current-Text :: <string>, 
	  File :: <stream>, blank :: <boolean>)
      => (result :: <string>, blank :: <boolean>);
    process-HTML(New-Tag, Out-Text, Current-Text, File, blank);
  end method;

// This tag action is a logical partner for "tag-start-recurse".  It simply
// exits so that control will return to an inclosing "process-HTML" call
// without distrubing the accumulated text.
define constant tag-close-nothing =
  method (tag :: <symbol>, Out-Text :: <strings>, blank :: <boolean>)
    blank;
  end method;

// Specialized "add-text" methods provide EMPHASIZED versions of "<B>" or
// "<I>" style environments.
add-tag(#["I", "EM", "CITE", "VAR", "DFN"],
	add-text: method(text :: <string>) => (result :: <string>);
		      if (*Icap*.value) as-uppercase(text) else text end
		  end method,
	tag-start: tag-start-recurse,
	tag-close: tag-close-nothing);

add-tag(#["B", "STRONG"],
	add-text: method(text :: <string>) => (result :: <string>);
		      if (*Bcap*.value) as-uppercase(text) else text end
		  end method,
	tag-start: tag-start-recurse,
	tag-close: tag-close-nothing);

// Anchors do nothing at all.
add-tag(#["A", "HEAD", "BODY", "UNKNOWN", "TT", "CODE", "SAMP", "KBD"],
	tag-start: tag-start-recurse,
	tag-close: tag-close-nothing);

// Titles are eliminated entirely -- add-text simply "adds" an empty string.
add-tag(#["TITLE"], 
	add-text: method(text :: <string>) => (res :: <string>); "" end method,
	tag-start: tag-start-recurse,
	tag-close: tag-close-nothing);

// For un-bracketed environments like "<P>", "<BR>", etc. we must make sure
// "tag-start" does not start a recursive call to "process-HTML".  We may or
// may not want to dump accumulated text.
add-tag(#["!"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>, 
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     values(Current-Text, blank);
		   end method);

add-tag(#["P"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>, 
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     values(Current-Text,
			    break-up(Old-Tag, Out-Text, blank, #t));
		   end method);

add-tag(#["BR"], 
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>, 
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     if (Pre-Count > 0)
		       add-eol(Out-Text);
		       values(Current-Text, blank);
		     else
		       values(Current-Text,
			      break-up(Old-Tag, Out-Text, blank, #f));
		     end if;
		   end method);

add-tag(#["HR"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     break-up(Old-Tag, Out-Text, blank, #t);
		     force-output(*window-stream*);
		     let start-index = end-mark.value;
		     write-line(*window-stream*,
				concatenate('-' * *linelen*, "\n"));
		     force-output(*window-stream*);
		     add-tag(bold-tag, start: start-index,
			     end: text-at(start-index.line,
					  start-index.character + *linelen*));
		     values(Current-Text, #t);
		   end method);

add-tag(#["IMG"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     break-up(Old-Tag, Out-Text, blank, #t);
		     write-line(*window-stream*,
				concatenate(' ' * (*margin* + 4),
					    "*** INLINE IMAGE IGNORED ***\n"));
		     values(Current-Text, #t);
		   end method);

// Preformatted text is tricky.  First we dump accumulated text.  Then we
// increment the global variable "Pre-Count" which enables magic behavior in
// several standard routines.  Finally, when the environment is closed, we
// split the output around the newlines and do line-by-line output so that the
// left margin will be observed.
add-tag(#["PRE"],
	break-up: method (text :: <string>, blank :: <boolean>,
			  want-blank :: <boolean>) => (result :: <boolean>);
		    unless(blank) write-element(*window-stream*, '\n'); end;
		    let first = sfind(text, curry(\~=, '\n'));
		    let last = rsfind(text,
				      complement(rcurry(member?, "\n ")));
		    if (last)
		      while (first < last)
			let endline = sfind(text, curry(\=, '\n'),
					    start: first, failure: last + 1);
			print-with-prefix(text, start: first, end: endline);
			first := endline + 1;
		      end while;
		    end if;
		    write-string("\n");
		    #t
		  end method,
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     let blank = break-up(Old-Tag, Out-Text, blank, #t);
		     block ()
		       Pre-Count := Pre-Count + 1;
		       process-HTML(New-Tag, Out-Text, Current-Text,
				    File, blank);
		     cleanup
		       Pre-Count := Pre-Count - 1;
		     end block;
		   end method);

// Since the following methods add nested indentation levels, we create a
// stack for the margins.  A "document state" record might be cleaner, but is
// probably overkill for this particular application.
define constant margins :: <Deque> = make(<Deque>);

add-tag(#["UL", "OL", "MENU", "DL", "BLOCKQUOTE"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     break-up(Old-Tag, Out-Text, blank, #t);
		     let OldCounter = counter;
		     block ()
		       push(margins, *margin*);
		       *margin* := *margin* + 4;
		       counter := 0;
		       process-HTML(New-Tag, Out-Text, Current-Text,
				    File, blank);
		     cleanup
		       *margin* := pop(margins);
		       counter := OldCounter;
		     end block;
		   end method);

// The "<LI>" tag causes bullets or numbers to be printed before the
// immediately following text.  We use a global "prefix" variable to magically
// change the behavior of the next call to "print-with-prefix".  The precise
// choice of prefix depends upon the enclosing environment.
add-tag(#["LI"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     let blank = break-up(Old-Tag, Out-Text, blank, #f);
		     if (Old-Tag = #"OL")
		       counter := counter + 1;
		       prefix := copy-sequence("0. ");
		       prefix[0] := as(<character>,
				       counter + as(<integer>, '0'));
		     else
		       prefix := "* ";
		     end if;
		     values(Current-Text, blank);
		   end method);

// In "<DL>" environments, we must simply switch the left margin back and
// forth between "unindented" and "indented" depending on whether we are
// currently processing a "term" or a "definition".
add-tag(#["DT"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     let blank = break-up(Old-Tag, Out-Text, blank, #f);
		     *margin* := first(margins);
		     values(Current-Text, blank);
		   end method);

add-tag(#["DD"],
	tag-start: method (New-Tag :: <symbol>, Old-Tag :: <symbol>,
			   Out-Text :: <strings>, Current-Text :: <string>,
			   File :: <stream>, blank :: <boolean>)
		       => (result :: <string>, blank :: <boolean>);
		     let blank = break-up(Old-Tag, Out-Text, blank, #f);
		     *margin* := first(margins) + 4;
		     values(Current-Text, blank);
		   end method);

// Headers may centered and/or underlined and ignore margins.  They must still
// be broken up into lines, although we use a shorter line-length.
add-tag(#["H1"],
	break-up: method (text :: <string>, blank :: <boolean>,
			  want-blank :: <boolean>)  => (result :: <boolean>);
		    unless(blank) write-element(*window-stream*, '\n'); end;
		    let text
		      = if (*H1cap*.value) as-uppercase(text) else text end if;

		    let first = sfind(text, curry(\~=, ' ')); 
		    let Text-Size = size(text);
		    let Find-Break = 
		      method (first, last)
			if (last >= Text-Size)
			  Text-Size;
			else 
			  let find = rsfind(text, curry(\=, ' '),
					    start: first, end: last); 
			  if (find)   
			    rsfind(text, curry(\~=, ' '), 
				   start: first, end: find) + 1 
			  else 
			    sfind(text, curry(\=, ' '), start: first)
			      | size(text)
			  end if
			end if
		      end method; 
		    let Max-Length = 0;
		    while (first)
		      let last = Find-Break(first, first + *linelen* - 20);
		      Max-Length := max(Max-Length, last - first);
		      
		      write-string(' ' * truncate/(*linelen* + first - last,
						   2));
		      force-output(*window-stream*);
		      let start-index = end-mark.value;
		      write-line(*window-stream*, text,
				 start: first, end: last);
		      force-output(*window-stream*);
		      add-tag(bold-tag, start: start-index,
			      end: text-at(start-index.line,
					   start-index.character
					     + last - first));
		      first := sfind(text, curry(\~=, ' '), start: last + 1)
		    end while;
		    if (*H1under*.value)
		      write-string(' ' * truncate/(*linelen* - Max-Length, 2));
		      write-line(*window-stream*, '=' * Max-Length); 
		    end if;
		    if (want-blank) write-string("\n")  end if; 
		    want-blank 
		  end method);

add-tag(#["H2"],
	break-up: method (text :: <string>, blank :: <boolean>,
			  want-blank :: <boolean>)  => (result :: <boolean>);
		    unless(blank) write-element(*window-stream*, '\n'); end;
		    let text
		      = if (*H2cap*.value) as-uppercase(text) else text end if;

		    let first = sfind(text, curry(\~=, ' ')); 
		    let Text-Size = size(text);
		    let Find-Break = 
		      method (first, last)
			if (last >= Text-Size)
			  Text-Size;
			else 
			  let find = rsfind(text, curry(\=, ' '),
					    start: first, end: last); 
			  if (find)   
			    rsfind(text, curry(\~=, ' '), 
				   start: first, end: find) + 1 
			  else 
			    sfind(text, curry(\=, ' '), start: first)
			      | size(text)
			  end if
			end if
		      end method; 
		    let Max-Length = 0;
		    while (first)
		      let last = Find-Break(first, first + *linelen* - 20);
		      Max-Length := max(Max-Length, last - first);
		      force-output(*window-stream*);
		      let start-index = end-mark.value;
		      write-line(*window-stream*, text,
				 start: first, end: last); 
		      force-output(*window-stream*);
		      add-tag(bold-tag, start: start-index,
			      end: text-at(start-index.line,
					   start-index.character
					     + last - first));
		      first := sfind(text, curry(\~=, ' '), start: last + 1)
		    end while;
		    if (*H2under*.value)
		      write-line(*window-stream*, '-' * Max-Length);
		      #f;
		    else
		      write-element(*window-stream*, '\n');
		      #t
		    end if;
		  end method);

add-tag(#["H3", "H4", "H5", "H6"],
	break-up: method (text :: <string>, blank :: <boolean>,
			  want-blank :: <boolean>)  => (result :: <boolean>);
		    unless(blank) write-element(*window-stream*, '\n'); end;
		    block ()
		      push(margins, *margin*);
		      *margin* := 0;
		      add-text-table[#"TEXT"](text, #t, want-blank);
		    cleanup
		      *margin* := pop(margins);
		    end;
		  end method);
