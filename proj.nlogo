globals[lair-x lair-y spd-walk spd-run global-hunger feeding-rate
  timer-body size-hyena
  max-angle-turn vision];;flocking var
patches-own [ground savane water rocky lair meat
  timerp-1 timerp-2]

;;--------------------------
;;---Hyanas inner working---
;;--------------------------
breed[hyenas hyena]
hyenas-own [debug
  age rank strength hunger target t-called m-called heat life hungry
  timer1 timer2 timer-R timer-att
]

;;-----------------
;;---Other breed---
;;-----------------
breed [preys prey]
preys-own [thirt flockmates obstacles nearest-neighbor life panic dangers]
breed [predators predator]

;;-------------------
;;-------INIT--------
;;-------------------
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ;;----init globals----
  set spd-walk 0.1
  set spd-run 0.3
  set feeding-rate 0.005
  set size-hyena 5

  ;;----init world----
  repeat nb-water [init-water]
  init-diffuse-water
  init-savane
  init-lair
  init-diffuse-lair

  ;;----init hyenas----
  let rk 4
  repeat 5[
    create-hyenas nb-hyenas / 5 [
      init-hyenas rk
    ]
    set rk rk - 1
  ]
  create-hyenas 1[
   init-matriach
  ]
  ;;-----init preys-----
  repeat initial-prey[
    let xx random-xcor
    let yy random-ycor
    create-preys 5 + random 10[
      init-prey xx yy
    ]
  ]

  ;;----init display world----
  ask patches [display-ground ]

  ;;---init flock---
 set max-angle-turn 124
 ;; set factor-align 0.4
 ;; set factor-cohere 0.1
 ;; set factor-separate 0.0
  set vision 20
end

;;---------------------------------------------------------
;;-------------------init and display----------------------
;;---------------------------------------------------------

to init-hyenas [rk]
  set shape "wolf 7"
  set hunger 100
  set life 100
  set age 1
  set rank rk
  set label rank
  set strength 10 + random 50
  set size 5 + size-hyena - (2 - (strength / 60) * 2)
  set m-called nobody
  set hungry false
  ifelse rank = 0 [set color blue][set color pink]
  let continue 1
  set target nobody
  while[continue = 1][
    let xx lair-x + random 10 - random 10
    let yy lair-y + random 10 - random 10
    if(in-map xx yy)[
     setxy xx yy
     set continue 0
    ]
  ]
end

to init-matriach
  set color red
  set shape "wolf 7"
  set size size-hyena + 6
  set hunger 100
  set life 100
  set age 1
  set rank 5
  set hungry false
  set label rank
  set strength 60
  set m-called nobody
  set target nobody
  setxy lair-x lair-y
end

to init-prey [xxx yyy]
  set color grey
  set shape "moose"
  set thirt 100
  set size 5
  set panic 0
  set life 100
  let continue 1
  while[continue = 1][
    let xx xxx + random 10 - random 10
    let yy yyy + random 10 - random 10
    if([water] of patch xx yy < 0.5)[
     setxy xx yy
      let test min-one-of other preys in-radius 0 [distance myself]
      if(test != nobody)[face test rt 180 lt random 25 rt random 25 fd spd-walk]
      set continue 0
    ]
  ]
end

to init-water
  let continue 1
  while [continue = 1][
    let xx random-xcor
    let yy random-ycor
    ask patch xx yy [
      if((lair = 0) and (water = 0) and (rocky = 0))[
        set water 100 + random 200
        set continue 0

        repeat random 10 [
          let xxx xx + random 20 - random 20
          let yyy yy + random 20 - random 20
          if(in-map xxx yyy)
          [ask patch xxx yyy [set water 100 + random 200]]
        ]
      ]
    ]
  ]
end

to-report in-map [xx yy]
  report (xx > min-pxcor and xx < max-pxcor and yy > min-pycor and yy < max-pycor)
end

to init-savane
  ask patches[
    set savane 50 + random 50
    if water > 0.9 [set water 0.9]
  ]
  ask patches [
    set savane mean [savane] of neighbors4
    if(water > 0.2)
    [set water (water - 0.2 + random-float 0.2)]
  ]
  ask patches [
    set water mean [water] of neighbors
  ]
end

to init-diffuse-water
  repeat 40 + random 20[
    diffuse water 0.90
  ]
end

to init-diffuse-lair
  repeat 100 [
    diffuse lair 0.90
  ]
end

to init-lair
  let continue 1
  while[continue = 1][
    let xx random-xcor
    let yy random-ycor
    ask patch xx yy [
      let test one-of patches with [water > 0.2] in-radius 20
      if(test = NOBODY)[
        ask patch xx yy [set lair 300]
        set lair-x xx set lair-y yy
        set continue 0
      ]
    ]
  ]

end

to display-ground
  ifelse(meat = 0)[
    ifelse(lair > 0.2) [
    set pcolor scale-color brown lair  0 1
    ]
    [ifelse(water > 0.2) [
      let w water
      if (w > 50) [set w 50]
      set pcolor scale-color blue water 1.5 -1
      ]
      [
        let colors [114 69 0]
        set pcolor scale-color brown savane  0 200
      ]
    ]
  ];;end if no meat
  [set pcolor red];;end if meat
end



;;-------------------------------------------------------------
;;---------------------GO and timed events---------------------
;;-------------------------------------------------------------
to go
  ask hyenas [IA-hyenas]
  ask preys [IA-preys]
  ask preys [rt random 90 lt random 90 fd spd-walk]
  if(count hyenas > 0)[
    set global-hunger mean [hunger] of hyenas
  ]
  ;;corpse-generator
  let cnt count preys
  if(respawn and cnt < initial-prey * 10) [spawn-prey]

  update-plots
end

to corpse-generator
  ifelse(timer-body = 0)[
    ask patch random-xcor random-ycor [set meat 25 display-ground]
    set timer-body 300 + random 600
  ]
  [set timer-body timer-body - 1  ]
end

to-report mean-hyenas [rang]
  report mean [hunger] of hyenas with [rank = rang]
end

to-report plot-strength [maxi mini]
  report mean [hunger] of hyenas with [strength < maxi + 1 and strength > mini]
end

;;---------------------------------------------------
;;---------------------IA Hyanas---------------------
;;---------------------------------------------------

to IA-hyenas
  let surrounding count predators in-radius 10
  ifelse surrounding > 0 [predator-interract surrounding]
  [ifelse t-called = 1 [defend-territory]
    [if(m-called = nobody) [set m-called min-one-of patches in-radius 20 with [meat > 0] [distance myself]]
      ifelse (hungry = true and m-called != nobody)[eat-meat]
      [ifelse (hungry = true or global-hunger < hunger-threshold) [hunt]
        [set surrounding min-one-of hyenas in-radius 5 with [age = 0] [distance myself]
          ifelse surrounding != nobody [feed surrounding]
          [ifelse heat > heat-threshold [reproduce]
            [frolic];;end reproduce
          ];;end feed children
        ];;end hunt
      ];;end eat meat
    ];;end defend
  ];;end predator
  update-hyenas
end

to update-hyenas
  set hunger hunger - feeding-rate
  ifelse hunger < hunger-threshold [ set hungry true]
  [if hunger > hunger-threshold + (hunger-threshold * 0.10) [set hungry false]]
  ;;set heat heat + feeding-rate
  ifelse(timer-att > 0)[set timer-att timer-att - 1]
  [set timer-att 0]
  if hunger < 1 [set life life - 1]
end

to predator-interract [surronding]
  set debug "predator-interact"
end

to defend-territory
  set debug "defend"
end

to eat-meat ;;hierarchi order
  ifelse (([meat] of m-called) = 0) [set debug "no" set m-called nobody]
  [;;if there is still meat
    let yippy m-called
    ask hyenas [if m-called = nobody [set m-called yippy] ]
    ifelse(distance m-called < 1)[;;close test
      set debug "eating"
      let surrounding 0
      if rank-influence
      [
        set surrounding count other hyenas in-radius 15 with [hunger < hunger-threshold and rank > [rank] of myself and strength > [strength] of myself]
      ]
      ifelse surrounding < 4[
        ask m-called [ set meat meat - 5 if(meat < 1) [set meat 0 display-ground]]
        set hunger hunger + 0.05
      ][;;wait in line
        fiddle
      ]
    ][;; if too far
      set debug "closing distance"
      face m-called fd spd-walk
    ]
  ]

end

to hunt
  set debug "hunt"
  ifelse target = nobody [ ;; no previous target
    set target min-one-of preys in-radius 15 [distance myself]
    ifelse(target != nobody)[;;target found
      let number count preys in-radius 7
      ifelse(number > 3)[ ;; if in pack
        ifelse(distance target > 7)[;; if too far
          face target fd spd-walk
        ][;; if too close
          face target rt 180 fd spd-walk
        ]
      ][;;if alone
        if(target != nobody)[face target fd spd-run]
      ]
    ][;;no target
      rt random 15
      lt random 15
      fd spd-walk
    ]
  ][;;follow previous target
    ifelse((distance target) < 2.5) [;;in reach to attack
      if(timer-att = 0)[
        ask target [ set life life - [strength] of myself]
      ]
    ][;;if too far
      set target min-one-of preys in-radius 15 [distance myself]
      let number count preys in-radius 15
      ifelse(number > 3)[ ;; if in pack
        ifelse(distance target > 13)[;; if too far
          face target fd spd-walk
        ][;; if too close
          let nei min-one-of other hyenas in-radius 5 [distance myself] ;;neighbor
          ifelse(nei != nobody)[;;if ally close
            face nei rt 180 fd spd-walk
          ][;;if close and no ally
            face target rt 90 fd spd-walk
          ]
        ]
      ][;;if alone
        if(target != nobody)[face target fd spd-run]
      ]
    ]
  ]
end

to feed [surronding]
  set debug "feed children"
end

to reproduce
  set debug "repoduce"
end

to frolic
  set debug "frolic"
  ifelse (distance patch lair-x lair-y < 40)
  [ rt random 45
    lt random 45
  ]
  [face patch lair-x lair-y
    rt random 90
    lt random 90
  ]
  fd spd-walk
end

to fiddle
  rt random 180
  lt random 180
end

;;---------------------------------------------------
;;---------------------IA Others---------------------
;;---------------------------------------------------

to find-obstacles
  set obstacles patches in-cone 9 60 with [water > 0.1]
end

to find-predators
  set dangers hyenas in-radius 10
end

to update-preys
  let base-meat 5500
  find-obstacles
  find-predators
  set thirt thirt - feeding-rate
  if(life < 1)[
     ask patch xcor ycor [set meat base-meat display-ground]
    if(random 2 = 0) [ ask patch (xcor + 1) ycor [set meat (base-meat / 5)  display-ground] ]
    if(random 2 = 0) [ ask patch (xcor - 1) ycor [set meat (base-meat / 5) display-ground] ]
    if(random 2 = 0) [ ask patch xcor (ycor + 1) [set meat (base-meat / 5) display-ground] ]
    if(random 2 = 0) [ ask patch xcor (ycor - 1) [set meat (base-meat / 5) display-ground] ]
    die
  ]
end

to flee
  ifelse panic > panic-threshold [
      rt random 45
      lt random 45
      fd spd-run * 0.4

  ]
  [
    if any? dangers
    [
      set panic panic + 1
      let d min-one-of dangers [distance myself]
      face d
      rt 180
      fd spd-run * 0.4
    ]
  ]
end

to IA-preys
  find-predators
  flock
  flee
  update-preys
end

to flock
  find-flockmates
  find-obstacles
  find-predators
  ifelse any? flockmates
  [let  v  vectDirect
    let a angleFromVect v
    turn-towards a max-angle-turn
  ]
  [ let v vectWithObstacles
    let a angleFromVect v
    turn-towards a max-angle-turn
  ]
end
;;----------------------------------------------------
;;---------------------Debug/Test---------------------
;;----------------------------------------------------

to erase-hyenas
  ask hyenas[die]
end

to spawn-hyenas
  let rk 4
  repeat 5[
    create-hyenas nb-hyenas / 5 [
      init-hyenas rk
    ]
    set rk rk - 1
  ]
  create-hyenas 1[
   init-matriach
  ]
end

to spawn-prey
  let xx random-xcor
  let yy random-ycor
    create-preys 5 + random 10[
      init-prey xx yy
    ]
end

;;-----------------------------------------------
;;---------------------Tools---------------------
;;-----------------------------------------------
to-report angleFromVect [vect]
    ifelse ((item 0 vect = 0) and (item 1 vect = 0))[
    report 0
  ][
    let a atan item 0  vect item 1 vect
    report a
  ]
end


to-report vectDirect
  let va multiplyScalarvect (factor-align * 4) vectAlign
  let vs multiplyScalarvect factor-separate vectSeparate
  let vc multiplyScalarvect (factor-cohere * 4) vectCohere
  let vo multiplyScalarvect (factor-obstacles * 4) vectObstacles

  let vr additionvect va vc
  set vr additionvect vr vs
  set vr additionvect vr vo
  report vr
;
end

to find-flockmates  ;; turtle procedure
  set flockmates other preys in-radius vision
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates with [xcor != [xcor] of myself and ycor != [ycor] of myself] [distance myself]
end

;;; SEPARATE


to-report vectSeparate
  let vs 0
  find-nearest-neighbor
  ifelse (nearest-neighbor = nobody)
     ; [set vs VectFromAngle random 180 0]
      [set vs list 0 0]
      [set vs VectFromAngle (towards nearest-neighbor + 180 ) (1 / distance nearest-neighbor)]
  report vs
end

to-report vectObstacles
  let vo (list 0 0)
  if any? obstacles [
    let nearest-patch min-one-of obstacles [distance myself]
    let d distance nearest-patch
    set vo VectFromAngle ((towards nearest-patch) + 180) (1 / d)
  ]
  report vo

end

to-report vectWithObstacles
  let vo multiplyScalarvect factor-obstacles vectObstacles
  report vo
end

;to separate  ;; turtle procedure
;  turn-away ([heading] of nearest-neighbor) max-separate-turn
;end

;;; ALIGN

to-report vectAlign
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  report (list x-component y-component)
end

;to align  ;; turtle procedure
;  turn-towards average-flockmate-heading max-align-turn
;end

;to-report average-flockmate-heading  ;; turtle procedure
;  ;; We can't just average the heading variables here.
;  ;; For example, the average of 1 and 359 should be 0,
;  ;; not 180.  So we have to use trigonometry.
;  let x-component sum [dx] of flockmates
;  let y-component sum [dy] of flockmates
;  ifelse x-component = 0 and y-component = 0
;    [ report heading ]
;    [ report atan x-component y-component ]
;end

;;; COHERE

to-report vectCohere

  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  report (list x-component y-component)
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

to-report multiplyScalarvect [factor vect]
   report (list (item 0 vect * factor) (item 1 vect * factor))
end
to-report additionvect [v1 v2]
   report (list (item 0 v1 + item 0 v2) (item 1 v1 + item 1 v2) )
end
to-report vectFromAngle [angle len]
   let l (list (len * cos angle) (len * sin angle))
   report l
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1020
501
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-200
200
-120
120
0
0
1
ticks
30.0

BUTTON
4
10
68
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
46
39
196
nb-hyenas
nb-hyenas
0
30
30.0
1
1
NIL
VERTICAL

SLIDER
45
47
78
197
nb-water
nb-water
1
10
4.0
1
1
NIL
VERTICAL

BUTTON
76
10
139
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
201
187
234
hunger-threshold
hunger-threshold
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
3
237
175
270
heat-threshold
heat-threshold
0
100
42.0
1
1
NIL
HORIZONTAL

BUTTON
1035
15
1143
48
NIL
erase-hyenas
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1145
15
1257
48
NIL
spawn-hyenas\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
84
45
117
195
initial-prey
initial-prey
0
4
3.0
1
1
NIL
VERTICAL

SLIDER
1036
59
1208
92
factor-align
factor-align
0
1
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
1035
95
1207
128
factor-cohere
factor-cohere
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
1036
131
1208
164
factor-separate
factor-separate
-1
1
0.3
0.1
1
NIL
HORIZONTAL

PLOT
1033
247
1233
397
Global Repletion
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot global-hunger"

SLIDER
1036
167
1208
200
factor-obstacles
factor-obstacles
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
278
177
311
panic-threshold
panic-threshold
50
300
50.0
1
1
NIL
HORIZONTAL

SWITCH
8
321
167
354
rank-influence
rank-influence
0
1
-1000

PLOT
6
504
674
773
By Rank
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Matriarch" 1.0 0 -10873583 true "" "plot mean-hyenas 5"
"Rank 4" 1.0 0 -2674135 true "" "plot mean-hyenas 4"
"Rank 3" 1.0 0 -1604481 true "" "plot mean-hyenas 3"
"Rank 2" 1.0 0 -534828 true "" "plot mean-hyenas 2"
"Rank 1" 1.0 0 -5516827 true "" "plot mean-hyenas 1"
"Male" 1.0 0 -13345367 true "" "plot mean-hyenas 0"

PLOT
681
504
1247
769
By Strength
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"60-50" 1.0 0 -10873583 true "" "plot plot-strength 60 50"
"50-40" 1.0 0 -2674135 true "" "plot plot-strength 50 40"
"40-30" 1.0 0 -1604481 true "" "plot plot-strength 40 30"
"30-20" 1.0 0 -13403783 true "" "plot plot-strength 30 20"
"20-10" 1.0 0 -13791810 true "" "plot plot-strength 20 0"

BUTTON
1261
15
1374
48
NIL
spawn-prey
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1238
57
1359
90
Respawn
Respawn
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

wolf 7
false
0
Circle -16777216 true false 183 138 24
Circle -16777216 true false 93 138 24
Polygon -7500403 true true 30 105 30 150 90 195 120 270 120 300 180 300 180 270 210 195 270 150 270 105 210 75 90 75
Polygon -7500403 true true 255 105 285 60 255 0 210 45 195 75
Polygon -7500403 true true 45 105 15 60 45 0 90 45 105 75
Circle -16777216 true false 90 135 30
Circle -16777216 true false 180 135 30
Polygon -16777216 true false 120 300 150 255 180 300

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
