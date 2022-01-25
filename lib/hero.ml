
module Abilities = struct
  type t = {
    strength : int
  ; dexterity : int
  ; constitution : int
  ; intelligence : int
  ; wisdom : int
  ; charisma : int
  }

  let init () =  {
    strength = 10
  ; dexterity = 10
  ; constitution = 10
  ; intelligence = 10
  ; wisdom = 10
  ; charisma = 10
  }
end

module type BONUS = sig
  type t
  val value : t
end

let bonus (x:Abilities.t) : (module BONUS with type t = Abilities.t) = (module struct
                                                                   type t = Abilities.t
                                                                   let value = x
                                                                 end)

let no_bonus = Abilities.{
    strength = 0
  ; dexterity = 0
  ; constitution = 0
  ; intelligence = 0
  ; wisdom = 0
  ; charisma = 0
  }

module type PLAYABLE = sig
  type t
  val make : string -> t
  val name : t -> string
end


module Race
    (B : BONUS with type t = Abilities.t) : PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name character = character.name
  let make name = {name ; abilities = Abilities.init()}
  let bonus = Abilities.{
      strength = B.value.strength
    ; dexterity = B.value.dexterity
    ; constitution = B.value.constitution
    ; intelligence = B.value.intelligence
    ; wisdom = B.value.wisdom
    ; charisma = B.value.charisma
    }
  let abilities character = Abilities.{
      strength = character.abilities.strength + bonus.strength
    ; dexterity = character.abilities.dexterity + bonus.dexterity
    ; constitution = character.abilities.constitution + bonus.constitution
    ; intelligence = character.abilities.intelligence + bonus.intelligence
    ; wisdom = character.abilities.wisdom + bonus.wisdom
    ; charisma = character.abilities.charisma + bonus.charisma
    }
end

module Dwarf = Race (val bonus Abilities.{
    no_bonus with constitution = 2
  })
module Elf = Race (val bonus Abilities.{
    no_bonus with dexterity = 2
  })
module Halfling = Race (val bonus Abilities.{
    no_bonus with dexterity = 2
  })
module Tiefling = Race (val bonus Abilities.{
    no_bonus with charisma = 2  ; intelligence = 1
  })
module HalfOrc = Race (val bonus Abilities.{
    no_bonus with strength = 2
  })
(* We can add new race with ease. Humans have +1 for all abilities *)
module Human = Race (val bonus Abilities.{
    strength = 1
  ; dexterity = 1
  ; constitution = 1
  ; intelligence = 1
  ; wisdom = 1
  ; charisma = 1
  })

type compagnion = 
    | Human of Human.t
    | Elf of Elf.t
    | Dwarf of Dwarf.t
    | Halfling of Halfling.t
    | Tiefling of Tiefling.t
    | HalfOrc of HalfOrc.t


let catti = Human.make "Catti-brie" 
let regis = Halfling.make "Regis"
let bruenor = Dwarf.make "Bruenor Battlehammer"
let wulfgar = Human.make "Wulfgar"
let drizzt = Elf.make "Drizzt Do'Urden"


let companions = [ Human catti ; Halfling regis ; Dwarf bruenor ; Human wulfgar ; Elf  drizzt ]