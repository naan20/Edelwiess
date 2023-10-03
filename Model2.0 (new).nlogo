globals [
  total-population
  communities-founded
  number-of-drop-outs
  number-of-died-communities
  person-to-track

]

breed [people person]
breed [  communities community]
undirected-link-breed [member-links member-link]

;undirected-link-breed []

people-own [

  ;general

  internal-perturbation-impact
  external-perturbation-impact
  internal-perturbation-change
  external-perturbation-change

  ;values
  my-orientation
  value-system
  importance-self-transcendence-values
  importance-self-enhancement-values

  ;virtue
  virtue-of-generosity
  virtue-of-independency
  virtue-of-justice
  virtue-of-leadership

  receptiveness-to-group-pressures
  receptiveness-to-external-perturbations
  receptiveness-to-internal-perturbations

  ;moral concern
  level-of-moral-concern
  stage-of-moral-concern
  member-of-community?
  willingness-to-morally-expand

  list-of-people-I-know-in-stage3


  my-community
  time-in-stage-4


  met-neighbor?
  meeting-radius


]

communities-own [
  community-number
  creation-date
  number-of-members
  embedded-community?
  average-distance-members
]

to setup
  clear-all
    ask patches [set pcolor white]
  if static-seed? [random-seed static-seed]
  setup-population
  setup-person-to-track
  reset-ticks
end

to setup-population
  set total-population #self-transcendence-oriented-people + #no-specific-oriented-people + #self-enhancement-oriented-people
  repeat #self-transcendence-oriented-people [setup-person "self-transcendence-oriented"]
  repeat #no-specific-oriented-people [setup-person "no-specific-oriented"]
  repeat #self-enhancement-oriented-people [setup-person "self-enhancement-oriented"]
end

to setup-person [orientation]
  create-people 1 [
    set color 1
    set shape "person"
    set size 0.8
    setxy random-xcor random-ycor
    set my-orientation orientation
    setup-cognitive-architecture orientation
    setup-moral-concern-system
    set met-neighbor? false
    set member-of-community? false
  ]


end

to setup-cognitive-architecture [orientation]
  setup-value-system orientation
  align-value-system
  setup-virtue-system
end

to setup-value-system [orientation]
  if orientation = "self-transcendence-oriented"[
    set importance-self-transcendence-values normalize-data-in-range value-oriented-mean value-std-dev
    set importance-self-enhancement-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev]
  if orientation = "no-specific-oriented" [
   set importance-self-transcendence-values normalize-data-in-range 50 value-std-dev
    set importance-self-enhancement-values normalize-data-in-range 50 value-std-dev]


  if orientation = "self-enhancement-oriented"[
    set importance-self-transcendence-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-self-enhancement-values normalize-data-in-range value-oriented-mean value-std-dev]

  set value-system (list
  importance-self-transcendence-values
  importance-self-enhancement-values)
end

to align-value-system
  let dVt-Ve importance-self-transcendence-values +  importance-self-enhancement-values
  let V-correction 0
  if dVt-Ve > cd2-max-sum-antagonistic-value-pairs  [
    set V-correction ( (dVt-Ve - cd2-max-sum-antagonistic-value-pairs  ) / 2)
    set importance-self-transcendence-values importance-self-transcendence-values - V-correction
    set importance-self-enhancement-values importance-self-enhancement-values - V-correction
  ]
  if dVt-Ve < cd2-min-sum-antagonistic-value-pairs  [
    set V-correction ( (cd2-min-sum-antagonistic-value-pairs - dVt-Ve  ) / 2)
    set importance-self-transcendence-values importance-self-transcendence-values + V-correction
    set importance-self-enhancement-values importance-self-enhancement-values + V-correction
  ]
end

to setup-virtue-system
  set virtue-of-justice random 100
  set virtue-of-independency random 100
  set virtue-of-generosity random 100
  set virtue-of-leadership random 100
  set meeting-radius min-meeting-radius + (max-meeting-radius - min-meeting-radius) * (virtue-of-leadership / 100)
end

to setup-moral-concern-system
  set level-of-moral-concern 0
  set stage-of-moral-concern 1
  let ep-modifier 1
  ;receptiveness-to-external-perturbations
  if virtue-of-justice >= 30 and virtue-of-justice <= 70 [
    set ep-modifier ep-modifier - ep-reduction ]
  if virtue-of-independency < 30 [
    set ep-modifier ep-modifier - ep-reduction]
  if importance-self-transcendence-values < ep-ST-threshold1 [
    set ep-modifier ep-modifier - receptiveness-reducer-due-to-values * ep-reduction]
  if importance-self-transcendence-values < ep-ST-threshold2 [
    set ep-modifier ep-modifier - receptiveness-reducer-due-to-values * ep-reduction]
  set receptiveness-to-external-perturbations clamp 0.1 1 ep-modifier

  ;receptiveness-to-group-pressures
  ifelse virtue-of-independency <= 70
  [set receptiveness-to-group-pressures moral-expansion-change-group-pressures]
  [set receptiveness-to-group-pressures 0]

  ;receptiveness-to-internal-perturbations
  let ip-modifier 1
  if virtue-of-justice < 30 or virtue-of-justice > 70 [
    set ip-modifier ip-modifier - ip-reduction]
  if virtue-of-generosity < 30 or virtue-of-generosity > 70 [
    set ip-modifier ip-modifier - ip-reduction]
  if importance-self-enhancement-values < ip-EH-threshold1 [
    set ip-modifier ip-modifier - receptiveness-reducer-due-to-values * ip-reduction]
  if importance-self-enhancement-values < ip-EH-threshold2 [
    set ip-modifier ip-modifier - receptiveness-reducer-due-to-values * ip-reduction]
  set receptiveness-to-internal-perturbations clamp 0.1 1 ip-modifier
end

to go
  ask people [ set met-neighbor? false]
  generate-perturbations
  update-moral-concern-due-to-ep
  update-stages-of-moral-concern
  interact-with-neighbour
  update-stages-of-moral-concern
  weigh-self-interest-over-community
  check-if-community-can-sustain
  tick


end

to update-moral-concern-due-to-ep
  ask people [
    if stage-of-moral-concern < 3 [
      if internal-perturbation-change < abs (external-perturbation-change) [
        set level-of-moral-concern clamp 0 50 level-of-moral-concern + external-perturbation-change
      ]
    ]
  ]
end

to generate-perturbations
  let general-perturbation random-exponential perturbation-mean-exponential-distribution
  if random 100 < %-opposing-perturbation [ set general-perturbation general-perturbation  * -1 ]
    ask people [
    ifelse random 100 < %-global-perturbation  ;; determine on an individual level whether the global event applies for each individual. %-global-event = 30 means that durin each tick about 30% will not experience the global event but generate an individual event.
    [
      set external-perturbation-impact general-perturbation
    ]
    [set external-perturbation-impact random-exponential perturbation-mean-exponential-distribution
      if random 100 < %-opposing-perturbation [ set external-perturbation-impact external-perturbation-impact * -1 ]
    ]
    set internal-perturbation-impact random-exponential perturbation-mean-exponential-distribution
    set internal-perturbation-change internal-perturbation-impact * receptiveness-to-internal-perturbations
    set external-perturbation-change external-perturbation-impact * receptiveness-to-external-perturbations
  ]

end


to update-stages-of-moral-concern
  ask people [
    if level-of-moral-concern < 25 [
      set stage-of-moral-concern 1
      set color 1
      stop]
    if level-of-moral-concern < 50 [
      set stage-of-moral-concern 2
      set color 15
      stop]
    if level-of-moral-concern >= 50 and stage-of-moral-concern = 2 [
      set stage-of-moral-concern 3
      set list-of-people-I-know-in-stage3 (list self)
      set color 105
      stop]
    if level-of-moral-concern >= 50 and member-of-community? and stage-of-moral-concern = 3  [
      set stage-of-moral-concern 4
      set color 45
      set willingness-to-morally-expand initial-willingness-to-morally-expand-threshold
      set time-in-stage-4 0
      stop]
  ]
end

to interact-with-neighbour
  ask people [
    if met-neighbor? = false and any? other people in-radius meeting-radius with [met-neighbor? = false ]  [
      let neighbor-to-meet one-of other people in-radius meeting-radius with [met-neighbor? = false]
      start-interaction-with neighbor-to-meet
      set met-neighbor? true
      ask neighbor-to-meet [
        start-interaction-with myself
        set met-neighbor? true ]
    ]
  ]
end

to start-interaction-with [neighbor]
  ;;;;; stage-of-moral-concern = 2
  if stage-of-moral-concern = 2 [
    if virtue-of-independency > 30 [
      ifelse level-of-moral-concern >= [level-of-moral-concern] of neighbor
      [set level-of-moral-concern clamp 0 50 level-of-moral-concern + receptiveness-to-group-pressures]
      [set level-of-moral-concern level-of-moral-concern -  receptiveness-to-group-pressures]
    ]
    if virtue-of-independency >= 30 and virtue-of-independency <= 70 [
      if value-difference self neighbor < max-vd-independency3070-virtue [
        ifelse level-of-moral-concern >= [level-of-moral-concern] of neighbor
        [set level-of-moral-concern clamp 0 50 level-of-moral-concern + receptiveness-to-group-pressures]
        [set level-of-moral-concern level-of-moral-concern -  receptiveness-to-group-pressures]
      ]
    ]
  ]
  ;;;;; stage-of-moral-concern = 3
  if stage-of-moral-concern = 3 [
    if [stage-of-moral-concern] of neighbor = 3 [
      set list-of-people-I-know-in-stage3 remove-duplicates sentence list-of-people-I-know-in-stage3 [list-of-people-I-know-in-stage3] of neighbor
      foreach list-of-people-I-know-in-stage3 [
        x -> ask x [
          if stage-of-moral-concern != 3 [
            ask myself [set list-of-people-I-know-in-stage3 remove x list-of-people-I-know-in-stage3 ]
          ]
        ]
      ]
      if length list-of-people-I-know-in-stage3 >= min-numb-people-for-com [
        start-community ]
    ]
    if [stage-of-moral-concern] of neighbor >= 4 [
      if [number-of-members] of [my-community] of neighbor + length list-of-people-I-know-in-stage3 < max-numb-people-for-com [
        join-community [my-community] of neighbor
        foreach list-of-people-I-know-in-stage3 [
          x -> ask x [
            join-community [my-community] of myself
          ]
        ]
      ]
    ]
  ]
end

to weigh-self-interest-over-community
  ask people [
    if stage-of-moral-concern = 4 [
      set willingness-to-morally-expand willingness-to-morally-expand - internal-perturbation-impact * receptiveness-to-internal-perturbations + external-perturbation-impact * receptiveness-to-external-perturbations
      if willingness-to-morally-expand < 0 [
        quit-community
        set time-in-stage-4 0
        stop]
      set time-in-stage-4 time-in-stage-4 + 1
      if time-in-stage-4 > time-needed-to-morally-expand [
      set stage-of-moral-concern 5
      set color 55
      set shape "tree"
      stop
    ]
    ]
  ]

end

to check-if-community-can-sustain
  ask communities [
    if count member-link-neighbors with [stage-of-moral-concern = 5] >= min-numb-people-for-com [
      set embedded-community? true ]
    if number-of-members < min-numb-people-for-com [
      ask member-link-neighbors [
        set stage-of-moral-concern 3
        set member-of-community? false
        set my-community 0
        set shape "person"
        set color 105]
      ask my-member-links [die]
      set number-of-died-communities number-of-died-communities + 1
      die
    ]
  ]
  ask communities with [embedded-community? = true ] [
    let distances 0
    ask member-link-neighbors [
      set distances distances + distance myself]
    set average-distance-members distances / number-of-members
  ]

end

to start-community
  foreach list-of-people-I-know-in-stage3 [
    x -> set list-of-people-I-know-in-stage3 remove-duplicates sentence list-of-people-I-know-in-stage3 [list-of-people-I-know-in-stage3] of x]
  foreach list-of-people-I-know-in-stage3 [
        x -> ask x [
          if stage-of-moral-concern != 3 [
            ask myself [set list-of-people-I-know-in-stage3 remove x list-of-people-I-know-in-stage3 ]
          ]
        ]
      ]
 hatch-communities 1 [
    set communities-founded communities-founded + 1
    set community-number communities-founded
    set creation-date ticks
    set shape "bread"
    set size 2
    setxy [xcor] of myself [ycor] of myself
    foreach [list-of-people-I-know-in-stage3] of myself [
      x -> ask x [
        join-community myself
        update-stages-of-moral-concern
      ]
    ]

  ]
end

to join-community [commune]
  create-member-link-with commune
  set member-of-community? true
  set my-community commune
  ask commune [set number-of-members count in-member-link-neighbors]


end

to quit-community
  ask my-community [ set number-of-members number-of-members - 1]
  ask my-member-links [die]
  set stage-of-moral-concern 2
  set level-of-moral-concern 25
  set color 15
  set list-of-people-I-know-in-stage3 (list )
  set member-of-community? false
  set number-of-drop-outs number-of-drop-outs + 1
end


to-report value-difference [person1 person2]
  let vd abs([importance-self-transcendence-values] of person1 - [importance-self-transcendence-values] of person2)
  set vd vd + abs([importance-self-enhancement-values] of person1 - [importance-self-enhancement-values] of person2)
  report vd
end


to-report clamp [low high number]
  if number < low [
    report low
  ]
  if number > high [
    report high
  ]
  report number
end


to-report normalize-data-in-range [mean-data std-data]
  let x -1
  while [x < 0 or x > 100] [
    set x precision (random-normal mean-data std-data) 3 ]
  report x
end

to setup-person-to-track
  set person-to-track person number-of-person-to-track


end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
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

SWITCH
20
18
143
51
static-seed?
static-seed?
1
1
-1000

INPUTBOX
21
56
144
116
static-seed
7.0
1
0
Number

SLIDER
655
38
860
71
#self-transcendence-oriented-people
#self-transcendence-oriented-people
0
600
600.0
25
1
NIL
HORIZONTAL

SLIDER
656
75
866
108
#no-specific-oriented-people
#no-specific-oriented-people
0
600
0.0
25
1
NIL
HORIZONTAL

SLIDER
655
116
862
149
#self-enhancement-oriented-people
#self-enhancement-oriented-people
0
600
0.0
25
1
NIL
HORIZONTAL

BUTTON
26
134
89
167
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
27
173
90
206
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
27
210
102
243
go once
go
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
27
248
126
282
Go 10 years
repeat 520 [go]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

SLIDER
655
158
827
191
value-oriented-mean
value-oriented-mean
50
80
70.0
1
1
NIL
HORIZONTAL

SLIDER
655
196
827
229
value-std-dev
value-std-dev
0
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
655
232
916
265
cd2-max-sum-antagonistic-value-pairs
cd2-max-sum-antagonistic-value-pairs
70
130
130.0
1
1
NIL
HORIZONTAL

SLIDER
657
270
913
303
cd2-min-sum-antagonistic-value-pairs
cd2-min-sum-antagonistic-value-pairs
0
100
70.0
1
1
NIL
HORIZONTAL

TEXTBOX
658
15
808
35
Population
16
0.0
1

TEXTBOX
959
14
1128
54
Perturbations
16
0.0
1

SLIDER
956
39
1202
72
perturbation-mean-exponential-distribution
perturbation-mean-exponential-distribution
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
958
113
1148
146
%-opposing-perturbation
%-opposing-perturbation
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1217
103
1401
136
ep-reduction
ep-reduction
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
1216
143
1425
176
ep-ST-threshold1
ep-ST-threshold1
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1217
179
1426
212
ep-ST-threshold2
ep-ST-threshold2
0
100
25.0
1
1
NIL
HORIZONTAL

TEXTBOX
1219
15
1465
58
Agent's reaction to perturbations
16
0.0
1

PLOT
658
315
1147
489
Stages of Moral Concern
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
"Stage 1" 1.0 0 -16777216 true "" "plot count people with [stage-of-moral-concern = 1 ]"
"Stage 2" 1.0 0 -2674135 true "" "plot count people with [stage-of-moral-concern = 2 ]"
"Stage 3" 1.0 0 -13345367 true "" "plot count people with [stage-of-moral-concern = 3 ]"
"Stage 4" 1.0 0 -1184463 true "" "plot count people with [stage-of-moral-concern = 4 ]"
"Stage 5" 1.0 0 -13840069 true "" "plot count people with [stage-of-moral-concern = 5 ]"

PLOT
1239
364
1439
514
Receptiveness EP
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.2 1 -16777216 true "" "histogram [receptiveness-to-external-perturbations] of people"

PLOT
1479
210
1679
360
Interactions
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
"default" 1.0 0 -16777216 true "" "plot count people with [met-neighbor? = true]"

SLIDER
1477
55
1649
88
min-meeting-radius
min-meeting-radius
0
1
1.0
0.25
1
NIL
HORIZONTAL

SLIDER
1477
90
1649
123
max-meeting-radius
max-meeting-radius
min-meeting-radius
3
2.5
0.25
1
NIL
HORIZONTAL

SLIDER
958
149
1131
182
%-global-perturbation
%-global-perturbation
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
1479
169
1760
202
moral-expansion-change-group-pressures
moral-expansion-change-group-pressures
1
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
1478
132
1716
165
max-vd-independency3070-virtue
max-vd-independency3070-virtue
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1488
405
1680
438
min-numb-people-for-com
min-numb-people-for-com
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1489
440
1685
473
max-numb-people-for-com
max-numb-people-for-com
0
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
1222
248
1394
281
ip-reduction
ip-reduction
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
1219
286
1392
319
ip-EH-threshold1
ip-EH-threshold1
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1220
328
1393
361
ip-EH-threshold2
ip-EH-threshold2
0
100
25.0
1
1
NIL
HORIZONTAL

TEXTBOX
960
88
1127
110
EP
16
0.0
1

TEXTBOX
1223
222
1390
244
to Internal
13
0.0
1

PLOT
1238
520
1438
670
Receptiveness IP
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.2 1 -16777216 true "" "histogram [receptiveness-to-internal-perturbations] of people"

SLIDER
1492
597
1795
630
initial-willingness-to-morally-expand-threshold
initial-willingness-to-morally-expand-threshold
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
1493
631
1719
664
time-needed-to-morally-expand
time-needed-to-morally-expand
0
30
25.0
1
1
NIL
HORIZONTAL

MONITOR
1492
475
1622
520
NIL
number-of-drop-outs
17
1
11

MONITOR
1625
476
1795
521
NIL
number-of-died-communities
17
1
11

TEXTBOX
1489
383
1656
405
Energy Community 
16
0.0
1

TEXTBOX
1478
19
1645
41
Interactions
16
0.0
1

TEXTBOX
1494
570
1661
592
Willingness to expand
16
0.0
1

SLIDER
1217
42
1440
75
receptiveness-reducer-due-to-values
receptiveness-reducer-due-to-values
0.5
3
2.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
1223
84
1390
104
to External
13
0.0
1

BUTTON
28
288
127
322
Go 20 years
repeat 1040 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1494
671
1574
716
Stage fivers
count people with [stage-of-moral-concern = 5]
17
1
11

PLOT
92
675
653
893
Value distribution population
Value Prioritization
Number of People
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Self-Transcendence" 2.5 0 -5825686 true "" "histogram [importance-self-transcendence-values] of people "
"Self-Enhancement" 2.5 0 -13791810 true "" "histogram [importance-self-enhancement-values] of people "

PLOT
92
456
649
674
Virtue distribution
Virtue Score
People
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Justice" 2.5 0 -16777216 true "" "histogram [virtue-of-justice] of people"
"Generosity" 2.5 0 -13840069 true "" "histogram [virtue-of-generosity] of people"
"Independency" 2.5 0 -13345367 true "" "histogram [virtue-of-independency] of people"
"Leadership" 2.5 0 -2674135 true "" "histogram [virtue-of-leadership] of people"

INPUTBOX
46
902
201
962
number-of-person-to-track
90.0
1
0
Number

MONITOR
1492
523
1681
568
Number of existing Communities
count communities
17
1
11

PLOT
222
903
682
1053
Internal and external perturbation change
NIL
NIL
0.0
10.0
0.0
3.0
true
true
"" ""
PENS
"Internal" 1.0 0 -16777216 true "" "plot [internal-perturbation-change] of person-to-track"
"External" 1.0 0 -2674135 true "" "plot [external-perturbation-change] of person-to-track"

PLOT
694
903
894
1053
Level of Moral Concern
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
"default" 1.0 0 -16777216 true "" "plot [level-of-moral-concern] of person-to-track"

MONITOR
1112
954
1298
999
Prio Self-Transcendence Values
[importance-self-transcendence-values] of person-to-track
17
1
11

MONITOR
1116
1004
1293
1049
Prio Self-Enhancement Values
[importance-self-enhancement-values] of person-to-track
2
1
11

MONITOR
1111
903
1260
948
People I know in Stage 3
length [list-of-people-I-know-in-stage3] of person-to-track
17
1
11

PLOT
899
902
1099
1052
Stage of moral concern
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [stage-of-moral-concern] of person-to-track"

PLOT
1317
906
1517
1056
Willingness to morally expand
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [willingness-to-morally-expand] of person-to-track"

PLOT
660
490
1236
640
Morally expanded people (stage 5) per group
Ticks
People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Self-Transcendent People" 1.0 0 -16777216 true "" "plot count people with [stage-of-moral-concern = 5 and my-orientation = \"self-transcendence-oriented\"]"
"General oriented people" 1.0 0 -14835848 true "" "plot count people with [stage-of-moral-concern = 5 and my-orientation = \"no-specific-oriented\"]"
"Self-Enhancement People" 1.0 0 -2674135 true "" "plot count people with [stage-of-moral-concern = 5 and my-orientation = \"self-enhancement-oriented\"]"

MONITOR
50
985
209
1030
Orientation
[my-orientation] of person-to-track
17
1
11

MONITOR
1577
670
1886
715
Average distance members to embedded communities
mean [average-distance-members] of communities with [embedded-community? = true]
17
1
11

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

bread
false
0
Polygon -16777216 true false 140 145 170 250 245 190 234 122 247 107 260 79 260 55 245 40 215 32 185 40 155 31 122 41 108 53 28 118 110 115 140 130
Polygon -7500403 true true 135 151 165 256 240 196 225 121 241 105 255 76 255 61 240 46 210 38 180 46 150 37 120 46 105 61 47 108 105 121 135 136
Polygon -1 true false 60 181 45 256 165 256 150 181 165 166 180 136 180 121 165 106 135 98 105 106 75 97 46 107 29 118 30 136 45 166 60 181
Polygon -16777216 false false 45 255 165 255 150 180 165 165 180 135 180 120 165 105 135 97 105 105 76 96 46 106 29 118 30 135 45 165 60 180
Line -16777216 false 165 255 239 195

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

orbit 6
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210
Circle -7500403 true true 26 58 67
Circle -7500403 true true 206 58 67
Circle -7500403 true true 116 221 67

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
NetLogo 6.1.1
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
