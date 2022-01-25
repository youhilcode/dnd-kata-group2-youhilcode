# DnD Kata

This Kata aims to model a DnD 5th Edition Charater, with its attributes.
It will introduce somes S.O.L.I.D pratices applyed to OCaml

## Setup a project from scratch

### Create a package

First we need to make an opam package of our project. It's mandatory for Dune that we will use as build system.
We just have to create a file name `<PACKAGE_NAME>.opam`

```sh
touch dnd-kata.opam
```

Since we will not publish our package to [opam repository](http://opam.ocaml.org/packages/) this file may remains empty. If we would, we would have to [add metadata to describe our package](http://opam.ocaml.org/doc/Packaging.html)

### Create a dune project

[Dune](https://dune.build/) is a composable build system for OCaml projects _(and ReasonML and Coq)_. A project is a source tree, maybe containing one or more packages: a typical dune project will have a `dune-project` and one or more `<package>.opam`

So create the [dune-project](https://dune.readthedocs.io/en/stable/dune-files.html#dune-project) file with the `lang` and `name` stanzas :

```sh
echo '(lang dune 2.9)\n (name dnd-kata)' >> dune-project
```

You notice that `dune-project` is a manifest that use s-expression format.
It contains the version of Dune we will use and the name of the project.

> You may not be familiar with s-expression. It's just anothe data text format like json, yaml, xml or toml.
> this s-expression
>
> ```
> (lang dune 2.9)
> (name dnd-kata)
> ```
>
> can be read as this equivalent json
>
> ```
> {
>  "lang" : {"dune" :  "2.9"},
>  "name" : "dnd-kata"
> }
> ```

Each folder and subfolder to include in our package need also a [dune](https://dune.readthedocs.io/en/stable/dune-files.html#dune) file manifest. That the case of the root file, so create it:

```sh
echo '(dirs (:standard \ node_modules \ _esy))' >> dune
```

The `dirs` stanza allows specifying the sub-directories dune will include in a build. A directory that is not included by this stanza will not be eagerly scanned by Dune.

`(dirs (:standard \ node_modules \ _esy))` means include all directories except node_modules and \_esy

### Package management with esy

[Esy](esy.sh) is a toolchain for OCaml _(and ReasonML)_ inspired by the NPM workflow. It use opam and dune with some benefits :

- Unique CLI for the both tools
- Per project dependencies sandboxing
- Use of dependencies coming from many repositories : opam, npm, esy, git, local, ...
- A unique manifest to manage all the dune files

> If you don't already have esy installed, run `npm i -g esy`

First create the manifest :

```sh
touch package.json
```

and edit it

```json
{
    "name": "dnd-kata",
    "version": "0.0.1",
    "description": "New OCaml project",
    "license": "MPL-2.0",
    "scripts": {
        "start": "esy x dnd"
    },
    "dependencies": {
        "ocaml": ">=4.12",
        "@opam/dune": "*"
    },
    "devDependencies": {},
    "esy": {
        "build": "dune build -p #{self.name}",
        "release": {
            "releasedBinaries": [
                "dnd"
            ]
        }
    }
}
```

> Most of the npm `package.json` fields are recongnized by esy : https://docs.npmjs.com/cli/v6/configuring-npm/package-json
> Because esy needs more information about the project, it also extends package.json with new fields : https://esy.sh/docs/en/configuration.html

You notice that some dependencies are prefixed by a namespace : `@opam`. It tell esy which repository must be use to get the package.

At this step we can already do first install:

```
esy
```

From now you have 3 new folders:

- \_esy : contains all working and build files for esy. We neither want to commit it nor analyzed it with Dune
- node_modules : contains all sanboxed packages used by ours. We neither want to commit it nor analyzed it with Dune
- esy.lock : describes the exact tree that was generated, such that subsequent installs are able to generate identical trees, regardless of intermediate dependency updates. This folder **must** be commmited (similar to package-lock.json)

We are using ocaml platform in our IDE, so we must install `ocaml-lsp-server` package but because we don't need it for release we will add it as development dependency:

```
esy add -D @opam/ocaml-lsp-server
```

If you're familiar with `yarn` you noticed that `esy` mimic its commands.

### Dune

While Dune is an extremly powerfull build system, it may change your habits to manage a `dune` files per directory, using sexp.

Our project will contains a binary and a library, so create thier folders:
```sh
mkdir bin && mkdir lib
```

As subfolders of our package, each need its own dune manifest:
```sh
touch lib/dune && touch bin/dune
```

Each dune package is either a librairy or an executable. 

Start by editing `lib/dune` file which describe a [library](https://dune.readthedocs.io/en/stable/dune-files.html#library):
```sexp 
(library
 (name DnD)
 (public_name dnd-kata.lib)
 (ocamlc_flags
  (:standard -warn-error -a+31+8)))
```

- `name` stanza contains the name of the root module of our library. If there is a module of this name (`DnD`), only this module will be exposed, otherwise the library expose a module of this name that contains all modules of the folder.
- `public_name` stanza contains the name under which the library can be referred to as a dependency.

> The extension is optional, I usually use no extension for lib that aims to be published on opam or use `.lib` for business libs and `.test` for testing libs but it's just a convention.

- `ocamlc_flags` stanza contains OCaml compilation flags passed to [ocamlc](https://www.mankier.com/1/ocamlc#-warn-error). Default is `-a+31`, we want to add `Partial match: missing cases in pattern-matching` as an error rather than a warning: Its is warning code is **8** so we passed the flag `-a+31+8`.

Continue by editing `bin/dune` file which describe an [executable](https://dune.readthedocs.io/en/stable/dune-files.html#executable)
```sexp 
(executable
 (name dnd_app)
 (public_name dnd)
 (libraries dnd-kata.lib)
 (ocamlc_flags
  (:standard -warn-error -a+31+8)))
```

- `name` stanza contains the name of the root module of our executable.
- `public_name` stanza contains the name under which the executable can be run
- `libraries` stanza contains dependencies. They may come from dependencies we installed with esy or from this dune package. Here we add a dependency to our lib.

We can add an "Welcome to Faerûn" to have a minimal program.

```sh
echo 'let () = print_endline "Welcome to Faerûn !"' >> ./bin/dnd_app.ml
```

Then we can build our program by running:

```sh
esy
```

`esy` is an alias for `esy install & esy build`

Finally we can run our program with our start script:

```sh
esy start
```

`esy <SCRIPT_NAME>` run the script defined in the package.json scripts section. So here we defined `esy x dnd` as `start` script.

`esy x <BIN_NAME>` run the binary `<BIN_NAME>` which can either be a binary built by our package (like **dnd**) or a binary coming from a dependency. Thik it like the `npx` command from npm.


#### Excercice 1:

We want to use [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) a code formatting tool:

- add a new development dependencies : [ocamlformat](http://opam.ocaml.org/packages/ocamlformat/) and [ocamlformat-rpc](https://opam.ocaml.org/packages/ocamlformat-rpc/) 
    
> ⚠️ ocamlformat et ocamlformat-rpc come from opam
- add a `.ocamlformat` file at the root of the project. **You can copy-paste its content from a previous kata.**

- run `esy install`, then `esy build` and reopen your IDE.

Congratulation you have setup your first project by yourself, we are ready to explore Faerûn

## SOLID OCaml

### Objectives of this kata

While programming we often use abstractions to have:

- namespaces
- protocoles
- default value or implementations

We will explore how to do this by implementing a simplified character creator for Dungeons & Dragons

First create a file `./lib/hero.ml`: it will be first place for our work

### About DnD

Dungeons & Dragons a.k.a DnD is a role playing game where players play heroes in a fantasy setup.
The main setup for this game is Faerûn, a continent of the Abeir-Toril planet.
We will use the [Dungeons & Dragons 5th Edition System](./doc/SRD-OGL_V5.1.pdf) under the Open-Gaming License (OGL).

### We are the Dwarves

First we want to modelize Dwarves, one of the playable races in Faerûn, by their names.

We already know that a good way to have a namespace in OCaml is to use modules, so we can start with this representation:

```ocaml
module Dwarf = struct
  type t = string
end
```

In this implementation, the type of the module is infered. We can also make it explicit by adding a module signature and modelize Elves at the same time:

```OCaml
module Dwarf : sig
  type t = string
end = struct
  type t = string
end

module Elf : sig
  type t = string
end = struct
  type t = string
end
```

At this step we notice that the 2 modules are sharing the same signature. Since both Elf and Dwarf modules are representing playable heroes, it seems legit and we would make explicit that all playable heroes are sharing the same signature. To do that we can use a module type:

```OCaml
module type PLAYABLE = sig
  type t = string
end

module Dwarf: PLAYABLE = struct
  type t = string
end

module Elf : PLAYABLE = struct
  type t = string
end
```

You can think module type as an interface for modules. We can separate interfaces and implementation. Create a new file `./lib/hero.mli`. `.mli` files contains OCaml interfaces and `.ml` files contains OCaml implementations, if you know C/C++, you may be familiar with this concept like `.h` / `.c` or `.hpp` / `.cpp `.

Now you should have:

- **lib/hero.mli**:

```ocaml
module type PLAYABLE = sig
  type t = string
end

module Dwarf: PLAYABLE

module Elf : PLAYABLE
```

- **lib/hero.ml**:

```ocaml
module type PLAYABLE = sig
  type t = string
end

module Dwarf= struct
  type t = string
end

module Elf = struct
  type t = string
end
```

Other modules do not need to know the shape of a `PLAYABLE.t`, they only need to know it exists and the module should expose functions to work with it.

We call this make an **abstraction**:

```ocaml
module type PLAYABLE = sig
  type t
  val to_string : t -> string
  val of_string : string -> t
end
```

_The module type must be update in .mli and .ml_

Now each module of type PLAYABLE must implement those functions. Let's do it:

```ocaml
module Dwarf: PLAYABLE  = struct
  type t = {name : string}
  let to_string dwarf = dwarf.name
  let of_string name = {name}
end

module Elf : PLAYABLE = struct
  type t = string
  let to_string elf = elf
  let of_string name = name
end
```

Since `t` is abstract, you may notice that each module implementing `PLAYABLE` may have a different concret type for `t`. It's totally fine while they respect their module type contract.

From the hero module (main module in hero.ml file), we cannot access a concrete value of `t`, but we can create a dwarf or get a string representation.

```ocaml
let gimly = Dwarf.of_string "Gimly"
let () = Dwarf.to_string gimly |> print_endline
```

### Heroes have abilities

In DnD, a Hero is also represented by its abilities.
There are several option rules for abilities at the creation, we will only implement the _Standard scores_ one. At the beginning each ability have a value of 10:

```ocaml
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
```

We can upgrade our Dwarf modules this way:

```ocaml
module Dwarf: PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let to_string dwarf = dwarf.name
  let of_string name = {name ; abilities = Abilities.init()}
end
```

Naming for our function is no more logical, so we will update `PLAYABLE` module type and then `Elf` and `Dwarf` modules:

```ocaml
module type PLAYABLE = sig
  type t
  val name : t -> string
  val make : string -> t
end

module Dwarf: PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name dwarf = dwarf.name
  let make name = {name ; abilities = Abilities.init()}
end

module Elf: PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name elf = elf.name
  let make name = {name ; abilities = Abilities.init()}
end
```

### Races give modifiers

#### The Darves have a constition bonus +2.

In OCaml, modules are first-class, it means you can use module as value. So we can create a new module type to represent a bonus and functions to represent a bonus of 2:

```ocaml
module type BONUS = sig
  type t
  val value : t
end

let bonus_2 : (module BONUS with type t = int) = (module struct
    type t = int
    let value = 2
end)
```

`bonus_2` is a module as value. Because `t` is abstract we must add a type witness `with type t = int`.

To unwrap the value of the bonus we also need a getter:

```ocaml
let get_bonus b = let module M = (val (b : (module BONUS with type t = int))) in M.value
```

> If you need more explaination about First-Class, you should read : https://dev.realworldocaml.org/first-class-modules.html

Now we can write:

```ocaml
module Dwarf: PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name dwarf = dwarf.name
  let make name = {name ; abilities = Abilities.init()}
  let constitution dwarf = dwarf.abilities.constitution + get_bonus bonus_2
end
```

#### Also are Elves, Half-orc, Halflings, Tieflings

Dwarves are not the only race in Faerun. Each have a different constitution bonus. Half orcs have +1 while Elves, Halflings and Tieflings don't have constitution bonus.

When data varies inside a function we add a function parameter to avoid code duplication. We can do the same at module level. OCaml provides **functors** which are functional modules : function from module to module.

So we can create a `Race` functor:

```ocaml
module Race (B : BONUS with type t = int) : PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name character = character.name
  let make name = {name ; abilities = Abilities.init()}
  let constitution_bonus = B.value (* here we get the value from module B *)
  let constitution character = character.abilities.constitution + constitution_bonus
end
```

You read this as : the functor `Race` take a module `B` of type `BONUS` whom type `t` is `int` as parameter and then return a module of type `PLAYBLE`.

Then we can easily have our modules:

```ocaml
(* we add a function to manage all bonus *)
let bonus (x:int) : (module BONUS with type t = int) = (module struct
    type t = int
    let value = x
end)

(* we use our Race functor to create the five races *)
module Dwarf = Race (val bonus 2)
module Elf = Race (val bonus 0)
module Tiefling = Race (val bonus 0)
module Halfling = Race (val bonus 0)
module HalfOrc = Race (val bonus 1)
```

#### All abilities may have bonus

Functors are not limited to one parameter, so we can use the same trick to manage all bonuses:

```ocaml
module Race
    (BS : BONUS with type t = int)
    (BD : BONUS with type t = int)
    (BC : BONUS with type t = int)
    (BI : BONUS with type t = int)
    (BW : BONUS with type t = int)
    (BCh : BONUS with type t = int) : PLAYABLE  = struct
  type t = {name : string ; abilities : Abilities.t}
  let name character = character.name
  let make name = {name ; abilities = Abilities.init()}
  let bonus = Abilities.{
      strength = BS.value
    ; dexterity = BD.value
    ; constitution = BC.value
    ; intelligence = BI.value
    ; wisdom = BW.value
    ; charisma = BCh.value
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

module Dwarf = Race (val bonus 0) (val bonus 0) (val bonus 2)(val bonus 0) (val bonus 0) (val bonus 0)
```

For your use case it's not so convenient, we have to remember the order of bonuses. We already have a type that represent all abilities values `Abilities.t`, just use it instead of `int`:

```ocaml
(* just create a bonus function that take a Abilities.t and return a Bonus module *)
let bonus (x:Abilities.t) : (module BONUS with type t = Abilities.t) = (module struct
    type t = Abilities.t
    let value = x
end)

(* the functor `Race` take a module `B` of type `BONUS` whom type `t` is `Abilities.t`
** as parameter and then return a module of type `PLAYBLE`  *)
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

(* create our Dwarf module *)
module Dwarf = Race (val bonus Abilities.{
    strength = 0
  ; dexterity = 0
  ; constitution = 2
  ; intelligence = 0
  ; wisdom = 0
  ; charisma = 0
  })
```

To be more concise and explicit we can work from a `no_bonus` value:

```ocaml
let no_bonus = Abilities.{
    strength = 0
  ; dexterity = 0
  ; constitution = 0
  ; intelligence = 0
  ; wisdom = 0
  ; charisma = 0
  }

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
```

#### Summary

At the end of this section you should have:

```ocaml

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
  val abilities : t -> Abilities.t
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
```

### United color of Faerûn

Each player may play a character from different race. How to modelize a team ?

#### The companions of the Hall

> The companions is a book from R.A. Salvatore a novelist who has written many novels set in Faerûn

We can create value for our teammates:

```ocaml
let catti = Human.make "Catti-brie"
let regis = Halfling.make "Regis"
let brenor = Dwarf.make "Bruenor Battlehammer"
let wulfgar = Human.make "Wulfgar"
let drizzt = Elf.make "Drizzt Do'Urden"
```

What if we create the companions:

```ocaml
❌ let companions = [catti; regis; bruenor; wulfgar;  drizzt]
```

**Error: This expression has type Halfling.t but an expression was expected of type
Human.t**

Remember the type of `list` has type `type 'a t = 'a list` , inference engine set`'a = Human.t` because it's the type of he first element of our list `catti`, but `regis` type is `Halfling.t`.

How could we help the compiler ? Type parameters must be concrete types.

```ocaml
(* won't compile PLAYABLE is a module type  *)
❌ type team = PLAYABLE.t list

(* won't compile RACE is a functor
** aka a function from module to module  *)
❌ type team = RACE.t list
```

#### Excercice 2:

Using the skills acquired during previous training find a solution to create our team of companions.

#### Exercice 3:

Heroes also have a class. For the kata, we will represent a `Class` by its name and hit dice.
We want to represent :

- Barbarian have a d12 hit dice
- Fighter and Rogue have a d8 hit dice
- Ranger have a d10 hit dice
- Wizard have a d6 hit dice

Then you must represent our companions by tuple :

- Catti-brie is a Human Fighter
- Regis is a Halfling Rogue
- Bruenor is a Dwarf Fighter
- Wulfgar is a Human Barbarian
- Drizzt is an Elf Ranger

### Exit Faerûn

We achieve first steps for a safe DnD heroes builder. It's just the beginning of the journey to a complete implementation: you have the SRD5 so you can do it if you're looking for a side project ¯\\_(ツ)_/¯

## Take away

OCaml provides abstractions for:

- namespaces: **module**
- protocole: **module type**
- extension: **functor**
- default value or implementation: **functor** or **first-class module**
  - functors are function from module to module
  - first-class modules are values and give a way to communicate between the type level and the module level. Exemple: a function from value to module.

SOLID is not only a OOP good pratice:

- Single responsibility principle => module
- Open/closed principle => module
- Liskov substitution principle => module type
- Interface segregation principle => module type
- Dependency inversion principle => functor
