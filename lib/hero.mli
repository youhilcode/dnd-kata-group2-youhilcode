module type PLAYABLE = sig
    type t
    val name : t -> string
    val make : string -> t
  end
  
  module Dwarf: PLAYABLE
  
  module Elf : PLAYABLE

