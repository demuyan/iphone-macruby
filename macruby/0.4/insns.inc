/** -*-c-*-
  This file contains YARV instructions list.
  
  ----
  This file is auto generated by insns2vm.rb
  DO NOT TOUCH!

  If you want to fix something, you must edit 'template/insns.inc.tmpl'
  or insns2vm.rb
 */


/* BIN : Basic Instruction Name */
#define BIN(n) YARVINSN_##n

enum ruby_vminsn_type {
  BIN(nop)                       = 0,

  BIN(getlocal)                  = 1,

  BIN(setlocal)                  = 2,

  BIN(getspecial)                = 3,

  BIN(setspecial)                = 4,

  BIN(getdynamic)                = 5,

  BIN(setdynamic)                = 6,

  BIN(getinstancevariable)       = 7,

  BIN(setinstancevariable)       = 8,

  BIN(getclassvariable)          = 9,

  BIN(setclassvariable)          = 10,

  BIN(getconstant)               = 11,

  BIN(setconstant)               = 12,

  BIN(getglobal)                 = 13,

  BIN(setglobal)                 = 14,

  BIN(putnil)                    = 15,

  BIN(putself)                   = 16,

  BIN(putcbase)                  = 17,

  BIN(putobject)                 = 18,

  BIN(putstring)                 = 19,

  BIN(concatstrings)             = 20,

  BIN(tostring)                  = 21,

  BIN(toregexp)                  = 22,

  BIN(newarray)                  = 23,

  BIN(duparray)                  = 24,

  BIN(expandarray)               = 25,

  BIN(concatarray)               = 26,

  BIN(splatarray)                = 27,

  BIN(checkincludearray)         = 28,

  BIN(newhash)                   = 29,

  BIN(newrange)                  = 30,

  BIN(pop)                       = 31,

  BIN(dup)                       = 32,

  BIN(dupn)                      = 33,

  BIN(swap)                      = 34,

  BIN(reput)                     = 35,

  BIN(topn)                      = 36,

  BIN(setn)                      = 37,

  BIN(adjuststack)               = 38,

  BIN(definemethod)              = 39,

  BIN(alias)                     = 40,

  BIN(undef)                     = 41,

  BIN(defined)                   = 42,

  BIN(postexe)                   = 43,

  BIN(trace)                     = 44,

  BIN(defineclass)               = 45,

  BIN(send)                      = 46,

  BIN(invokesuper)               = 47,

  BIN(invokeblock)               = 48,

  BIN(leave)                     = 49,

  BIN(finish)                    = 50,

  BIN(throw)                     = 51,

  BIN(jump)                      = 52,

  BIN(branchif)                  = 53,

  BIN(branchunless)              = 54,

  BIN(getinlinecache)            = 55,

  BIN(onceinlinecache)           = 56,

  BIN(setinlinecache)            = 57,

  BIN(opt_case_dispatch)         = 58,

  BIN(opt_checkenv)              = 59,

  BIN(opt_plus)                  = 60,

  BIN(opt_minus)                 = 61,

  BIN(opt_mult)                  = 62,

  BIN(opt_div)                   = 63,

  BIN(opt_mod)                   = 64,

  BIN(opt_eq)                    = 65,

  BIN(opt_neq)                   = 66,

  BIN(opt_lt)                    = 67,

  BIN(opt_le)                    = 68,

  BIN(opt_gt)                    = 69,

  BIN(opt_ge)                    = 70,

  BIN(opt_ltlt)                  = 71,

  BIN(opt_aref)                  = 72,

  BIN(opt_aset)                  = 73,

  BIN(opt_length)                = 74,

  BIN(opt_succ)                  = 75,

  BIN(opt_not)                   = 76,

  BIN(opt_regexpmatch1)          = 77,

  BIN(opt_regexpmatch2)          = 78,

  BIN(opt_call_c_function)       = 79,

  BIN(bitblt)                    = 80,

  BIN(answer)                    = 81,

};

#define VM_INSTRUCTION_SIZE 82
