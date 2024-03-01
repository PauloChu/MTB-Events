extensions [vid]
breed [residues residue]

residues-own [
  tumble ; tumble value of 0 is required for a run. A tumble value above 0 will make the turtle tumble. When a turtle starts tumbling, tumble value is 1 and decreases by 1 / own-tumble-duration each tick
  own-tumble-duration ; the tumble duration assigned to each turtle each tumble based on a normal distribution
  uturn  ; uturn value of 0 is required for a run. A uturn value above 0 will make the turtle uturn. When a turtle starts turning, uturn value is 1 and decreases by 1 / uturn each tick
  cooldown ; a cooldown period where, when above 0, will restrict any events. A turtle enters a cooldown after completing an event and it starts at 1 and decreases by 1  / eventcooldown each tick
]

globals [
  histogram-list
  numtumbles    ; the total number of tumbles performed by the turtles and logged on this variable
  numreverses   ; the total number of reverses performed by the turtles and logged on this variable
  shapevar      ; a variable used when the MTBshape variable is true. This variable logs the shape at which turtle's MTB is using and then randomly selects from a list to vary the shape of the MTB
  numuturns     ; the total number of uturns performed by the turtles and logged on this variable
  heading-noise ; the directional noise experienced by the turtles, based on the rotational force experienced by magnetotactic bacteria, as found in Yu et al. 2022
]

to set-heading-noise
  let Fr (4 * 10 ^ (-20))                          ; Force due to rotation, from Yu et al. 4 * 10 ^ - 20 kg m^2 /s
  let Dr ( ( 1.3806503 * 10 ^ (-23) * 300 ) / Fr ) ; Rotational diffusion. Dr = kT / Fr
  let var (2 * Dr * delta-t * ( 180 / pi ))        ; The variance of the rotational diffusion
  set heading-noise (sqrt ( var ))                 ; The standard deviation of the variance is then set to the variable 'heading-noise' which is then used to randomly vary the heading of the turtles
end

to setup
  clear-all
  reset-ticks
  setup-plot
  set histogram-list []
  set-heading-noise                                                          ; go through the procedure 'set-heading-noise' which calculates and sets the heading-noise variable
  create-residues numMTB [                                                   ; create the number of turtles as stated in the numMTB variable
    setxy random-xcor random-ycor                                            ; set random x and y coordinates for the turtles
    ifelse MTBshape [set shape "mtb1" ] [set shape "circle"]                 ; if MTBshape variable is true, then set the shape of the turtle to an MTB, otherwise to a circle
    set size 1.4 set color black                                             ; set the size of the turtles to 1.4 and colour them black
    if pendownstate [pendown]                                                ; if the pendownstate variable is true, set pendown, which adds a trailing line to all turtles
    set cooldown 1                                                           ; enable cooldown upon creating turtle to prevent events for the first few ticks
  ]
     ask patches [
     set pcolor white                                                        ; set the color of the patches to white (patches also known as the background)
   ]
  if saveimagesequence [export-view (word savedirectory date-and-time "_" numtumbles "tumbles_" numreverses "revereses_" numuturns "uturns" ".png")] ; export the current image if saveimagesequence is turned on
  if savepos [file-open word savedirectory "trajectories.csv"                ; setup a csv file to save the positons of all turtles for each tick
    file-type "Trajectory,x,y,Frame,tumble,reverse,uturn"
    file-type "\n"
    ask residues
    [
      file-type who
      file-type ","
      file-type xcor
      file-type ","
      file-type ycor
      file-type ","
      file-type ticks
      file-type ","
      file-type numtumbles
      file-type ","
      file-type numreverses
      file-type ","
      file-type numuturns
      file-type "\n"
    ]
    file-close
  ]
end

to go
  ask residues [                                                    ; begin commanding the turtles
    if die-on-border and (xcor < -15.5 or xcor > 15.5 or xcor < -15.5 or ycor > 15.5) [ setxy random-xcor random-ycor  set cooldown 1] ; kill turtle if they touch the border and re-position randomly in the simulation
    ifelse cooldown > 0 [                                           ; if turtle has a cooldown parameter greater than 0, then continue
      set cooldown cooldown - ( 1 / eventcooldown)                  ; reduce cooldown variable by 1/cooldown
      set heading heading + random-normal 0 heading-noise           ; change the heading of each turtle based on the heading based on rotational diffusion
      forward stepsize                                              ; take a step in the amount of the variable stepsize
    ]
    [
     ifelse uturn > 0[                                                             ; if the uturn parameter for the turtle is greater than 0, initiate uturn behaviour:
       set uturn abs (uturn) - ( 1 / uturn-duration )                              ; reduce uturn parameter by 1 / uturn-duration
       set heading heading + random-normal ( 180 / uturn-duration) heading-noise   ; increase the heading of the turtle by 180 / uturn-duration and adding the heading-noise
       if uturnstamp [set color blue stamp set color black]                        ; if uturnstamp is turned on, stamp the shape of the turtle as it moves through the uturn
       forward stepsize                                                            ; take a step in the amount of the variable stepsize
       if uturn <= 0 [set cooldown 1]                                              ; if the uturn is done then set the cooldown of the turtle to 1 to prevent back-to-back events
     ]
     [
       ifelse tumble > 0[                                                          ; if the tumble parameter for the turtle is greater than 0, initiate tumble behaviour:
         set tumble (tumble  - ( 1 / own-tumble-duration ))                        ; reduce tumble parameter by 1 / own-tumble-duration
         set heading random-float 360                                              ; set the heading randomly from 0 to 360 degrees
         if tumblestamp [set color red stamp set color black]                      ; if tumblestamp is turned on, stamp the shape of the turtle as it tumbles
         forward stepsize / 4                                                      ; move forward by a quarter of the stepsize
         if tumble <= 0 [set cooldown 1]                                           ; if the tumble is down, set cooldown of the turtle to 1 to prevent back-to-back events
       ][
         ifelse random-float 1 < probrev and (xcor < (max-pxcor - noeventperimeter)) and (xcor > (min-pxcor + noeventperimeter) ) and (ycor < (max-pycor - noeventperimeter)) and (ycor > (min-pycor + noeventperimeter) )[ ; if the turtle is not on the no event perimeter defined by patches and the random float is less than the probability of a reverse then:
           ifelse random-float 1 < probuturn[                                                       ; Randomly select a number between 0 and 1 and if it is less than the probability of a uturn, then uturn
             set uturn 1                                                                            ; Set uturn parameter to 1
             set uturn abs (uturn) - ( 1 / uturn-duration )                                         ; reduce uturn parameter by 1 / uturn-duration
             set heading heading + random-normal ( 180 / uturn-duration) heading-noise              ; increase the heading of the turtle by 180 / uturn-duration and adding the heading-noise
             if uturnstamp [set color blue stamp set color black]                                   ; if uturnstamp is turned on, stamp the shape of the turtle as it moves through the uturn
             set numuturns numuturns + 1                                                            ; increase the number of uturns that have been performed by one
             if uturn <= 0 [set cooldown 1]                                                         ; if the uturn is done then set the cooldown of the turtle to 1 to prevent back-to-back events
           ]
           [                                                                                        ; if the chance to do a uturn fails, then do a reverse:
             set heading heading + 180                                                              ; increase the heading of the turtle by 180 degrees
             if reversestamp[set color green stamp set color black]                                 ; if reversestamp is on then stamp the shape of the turtle as it reverses
             forward stepsize                                                                       ; take a step in the amount of the variable stepsize
             set numreverses numreverses + 1                                                        ; increase the number of reverses that have been performed by one
             set cooldown 1                                                                         ; set the cooldown of the turtle to 1 to prevent back-to-back events
           ]
         ][
           ifelse random-float 1 < probtumble and (xcor < (max-pxcor - noeventperimeter)) and (xcor > (min-pxcor + noeventperimeter) ) and (ycor < (max-pycor - noeventperimeter)) and (ycor > (min-pycor + noeventperimeter) )[ ; if the turtle is not on the no event perimeter defined by patches and the random float is less than the probability of a tumble then:
             set tumble 1                                                                           ; set tumble parameter to 1
             set own-tumble-duration abs ( random-normal tumble-duration (0.341 * tumble-duration) ); set the tumble duration of this specific tumble to a value selected from a normal distribution centered at the tumble-duration integer with one gaussian standard deviation
             set histogram-list lput own-tumble-duration histogram-list                             ; update the histogram of tumble durations
             set heading random-float 360                                                           ; randomly set the heading of the turtle
             forward stepsize / 4                                                                   ; move forward by a quarter of the stepsize
             set numtumbles numtumbles + 1                                                          ; increase the number of tumbles that have been performed by one
           ]
           [
             set heading heading + random-normal 0 heading-noise                                    ; if no event has been triggered, then set heading to a new heading based on a normal distibution centered at zero and the standard deviation is the heading noise calculated from the rotational diffusion
             forward stepsize                                                                       ; take a step in the amount of the variable stepsize
           ]
         ]
       ]
     ]
   ]
    if MTBshape[                                       ; if the boolean MTBshape is set to true, set the shape of the turtle to look like a sprillum bacterium
      set shapevar random 4 + 1                        ; select a number between 1 and 4
      set shapevar word "mtb" shapevar                 ; add the word mtb to the number
      set shape shapevar                               ; set the shape randomly between 4 shapes
    ]
  ]
  if saveimagesequence [export-view (word savedirectory date-and-time "_" numtumbles "tumbles_" numreverses "revereses_" numuturns "uturns" ".png")] ; export the current image if saveimagesequence is turned on
  if savepos [file-open word savedirectory "trajectories.csv" ask residues    ; add the position and other info to the csv file for all turtles for this tick
    [
      file-type who
      file-type ","
      file-type xcor
      file-type ","
      file-type ycor
      file-type ","
      file-type ticks
      file-type ","
      file-type numtumbles
      file-type ","
      file-type numreverses
      file-type ","
      file-type numuturns
      file-type "\n"
    ]
    file-close
  ]
  tick
  plot-p1
end



to setup-plot
  set-current-plot "Distribution of Tumble Durations"       ; set the plot and plot name for the tumble duration histogram
  set-plot-x-range 0 (tumble-duration * 3)                  ; set the x axis from 0 to triple the set tumble duration
  set-plot-y-range 0 500                                    ; set the y plot range from 0 to 500
end

to plot-p1
  set-current-plot "Distribution of Tumble Durations"       ; Access the tumble duration histogram
  histogram histogram-list                                  ; plot the histogram list with all of the tumble durations
end
@#$#@#$#@
GRAPHICS-WINDOW
232
21
701
491
-1
-1
13.97
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
19
330
191
363
probrev
probrev
0
1
0.02
0.001
1
per tick
HORIZONTAL

SLIDER
14
382
201
415
probtumble
probtumble
0
1
0.02
0.001
1
per tick
HORIZONTAL

SLIDER
27
166
199
199
numMTB
numMTB
0
100
1.0
1
1
NIL
HORIZONTAL

BUTTON
38
37
104
70
NIL
Setup
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
128
37
191
70
NIL
Go
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
954
277
1126
310
stepsize
stepsize
0
5
0.25
0.25
1
per tick
HORIZONTAL

SLIDER
24
537
204
570
tumble-duration
tumble-duration
0
50
15.0
1
1
ticks
HORIZONTAL

MONITOR
730
51
865
96
Number of Tumbles
numtumbles
17
1
11

MONITOR
890
51
1028
96
Number of Reverses
numreverses
17
1
11

SLIDER
25
581
197
614
uturn-duration
uturn-duration
0
50
15.0
1
1
ticks
HORIZONTAL

MONITOR
809
109
944
154
Number of U-Turns
numuturns
17
1
11

SWITCH
1089
61
1227
94
tumblestamp
tumblestamp
1
1
-1000

SWITCH
1257
107
1386
140
uturnstamp
uturnstamp
1
1
-1000

TEXTBOX
1177
27
1431
68
Visualize Events
15
0.0
1

TEXTBOX
819
19
969
38
Event Counters
15
0.0
1

TEXTBOX
40
299
190
318
Event Probabilities
15
0.0
1

TEXTBOX
38
133
188
152
Number of MTB
15
0.0
1

SWITCH
1248
61
1389
94
reversestamp
reversestamp
1
1
-1000

TEXTBOX
51
504
201
523
Length of Events
15
0.0
1

TEXTBOX
849
204
1063
242
Movement Parameters
15
0.0
1

INPUTBOX
323
541
618
601
savedirectory
0
1
0
String

SWITCH
363
613
543
646
saveimagesequence
saveimagesequence
1
1
-1000

TEXTBOX
406
513
556
532
Sequence Output
15
0.0
1

SWITCH
64
218
183
251
MTBshape
MTBshape
0
1
-1000

SWITCH
245
612
353
645
savepos
savepos
1
1
-1000

SWITCH
966
237
1114
270
die-on-border
die-on-border
1
1
-1000

SLIDER
18
437
193
470
probuturn
probuturn
0
1
0.0
0.01
1
per reverse
HORIZONTAL

SLIDER
742
236
957
269
noeventperimeter
noeventperimeter
0
14
2.0
1
1
patches
HORIZONTAL

TEXTBOX
49
12
202
30
Simulation Controls\n
14
0.0
1

SWITCH
1088
105
1231
138
pendownstate
pendownstate
1
1
-1000

SLIDER
749
278
928
311
eventcooldown
eventcooldown
0
100
10.0
1
1
ticks
HORIZONTAL

SLIDER
555
615
768
648
delta-t
delta-t
0
1
0.01
0.01
1
seconds per tick
HORIZONTAL

PLOT
1145
172
1402
360
Distribution of Tumble Durations
tumble-duration (ticks)
# of Tumbles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot histogram-list"

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

mtb1
true
15
Rectangle -1 true true 120 45 135 60
Rectangle -1 true true 135 60 150 75
Rectangle -1 true true 150 75 165 120
Rectangle -1 true true 135 120 150 150
Rectangle -1 true true 120 150 135 195
Rectangle -1 true true 135 195 150 210
Rectangle -1 true true 150 210 165 240
Rectangle -1 true true 165 240 180 270
Rectangle -1 true true 150 270 165 285

mtb2
true
15
Rectangle -1 true true 135 30 150 45
Rectangle -1 true true 120 45 135 60
Rectangle -1 true true 105 60 120 105
Rectangle -1 true true 120 105 135 135
Rectangle -1 true true 135 135 150 180
Rectangle -1 true true 120 180 135 195
Rectangle -1 true true 135 195 150 225
Rectangle -1 true true 150 225 165 255
Rectangle -1 true true 135 255 150 270

mtb3
true
15
Rectangle -1 true true 135 30 150 45
Rectangle -1 true true 150 45 165 60
Rectangle -1 true true 165 60 180 105
Rectangle -1 true true 180 105 195 135
Rectangle -1 true true 165 135 180 180
Rectangle -1 true true 150 180 165 195
Rectangle -1 true true 135 195 150 225
Rectangle -1 true true 120 225 135 255
Rectangle -1 true true 135 255 150 270

mtb4
true
15
Rectangle -1 true true 135 30 150 45
Rectangle -1 true true 120 45 135 60
Rectangle -1 true true 135 60 150 105
Rectangle -1 true true 120 105 135 135
Rectangle -1 true true 105 135 120 180
Rectangle -1 true true 120 180 135 195
Rectangle -1 true true 135 195 150 225
Rectangle -1 true true 150 225 165 255
Rectangle -1 true true 135 255 150 270

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
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
