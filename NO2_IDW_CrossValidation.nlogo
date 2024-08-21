__includes["csv_import_NO2background.nls" "csv_run_NO2background.nls"
  "csv_import_NO2road.nls"
  "crossval.nls"
  ;"csv_run_NO2road.nls"
]

extensions [csv gis]
globals [
  ;;; Admin
  gu road lc districtPop districtadminCode station_background station_road nox_weighting

  no2_bs

  ;;; Air Quality (Background)
  aq_BG1 aq_BG2 aq_BL0 aq_BQ7 aq_BX1 aq_BX2 aq_CT3 aq_EN1 aq_EN7 aq_GR4 aq_HG4 aq_HI0 aq_HR1 aq_IS6 aq_KC1
  aq_LB6 aq_LH0 aq_LW1 aq_LW5 aq_NM3 aq_RB7 aq_RI2 aq_SK6 aq_WA2 aq_WA9 aq_WM0

  ;;; Air Quality (Roadside)
  rd_BT4 rd_BT6 rd_BT8 rd_BY7 rd_CR5 rd_CT4 rd_CT6 rd_EA6 rd_EI1 rd_EN4 rd_EN5
  rd_GB6 rd_GN0 rd_GN3 rd_GN5 rd_GN6 rd_GR7 rd_GR8 rd_GR9 rd_HK6 rd_HV1 rd_HV3
  rd_IM1 rd_IS2 rd_KT4 rd_KT5 rd_KT6 rd_LB4 rd_LW4 rd_MY1 rd_NB1 rd_NM2 rd_RB4 rd_WA7
  rd_RI1 rd_SK8 rd_ST4 rd_ST6 rd_TH4 rd_TL4 rd_WAA rd_WAB rd_WAC rd_WM6 rd_WMB rd_WMC
]
breed [borough-labels borough-label]
patches-own [is-research-area? is-road? name homecode traffic nox_weight is-built-area?
  is-monitor-site? monitor-name monitor-code monitor-type nearest_station no2_list no2 ]


to setup
  clear-all
  file-close-all
  reset-ticks
  set-gis-data
  set-roads
  set-nox-weight
  set-urban-areas
  set-monitor-location
  set-air-pollution-background ;; in a separate source file
  set-air-pollution-road ;; in a separate source file
  set-nearest-station
  add-admin


end

to set-gis-data
  ask patches [set pcolor white]
  gis:load-coordinate-system (word "Data/London_Boundary_cleaned.prj")
  set gu   gis:load-dataset "Data/London_Boundary_cleaned.shp"
  set lc   gis:load-dataset "Data/London_LandCover.shp"
  set road gis:load-dataset "Data/London_Road_Dissolve.shp"
  set nox_weighting gis:load-dataset "Data/London_NOX.shp"

  ;set IMD gis:load-dataset "Data/London_LSOAs_IMD.shp"

  ;; patch size: approx 200m x 200m

  let base_envelope gis:envelope-of gu

  let span_x abs ( item 0 base_envelope - item 1 base_envelope )
  let span_y abs ( item 2 base_envelope - item 3 base_envelope )
  let alternating_spans ( list span_x span_x span_y span_y )
  let alternating_signs [ -1 1 -1 1 ]

  let expanded_envelope (
    map [ [ i span sign ] -> i + sign * ( 0.05 * span )  ]
    base_envelope alternating_spans alternating_signs
  )

  gis:set-world-envelope expanded_envelope
  ask patches gis:intersecting gu [set is-research-area? true]
  gis:set-drawing-color [64  64  64]    gis:draw gu 1

  ask patches with [is-research-area? != true][set is-research-area? false set name false set homecode false]


  ;; add GIS labels

  foreach gis:feature-list-of gu [vector-feature ->
  let centroid gis:location-of gis:centroid-of vector-feature
       if not empty? centroid
      [ create-borough-labels 1
        [ set xcor (item 0 centroid + 1) ;; added an arbitrary number due to the indented name setting
          set ycor item 1 centroid
          set size 0 ;; to hide the shape of the turtles
          set label-color blue
          set label gis:property-value vector-feature "NAME"
        ]]]
  output-print "GIS loaded"
end


to add-admin
  gis:set-drawing-color blue
  foreach gis:feature-list-of gu [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [set name gis:property-value vector-feature "NAME"
                                 set homecode gis:property-value vector-feature "GSS_CODE"]
 ]]
output-print "Admin area added" ;;
end


to set-roads
  let road-patches patches with [gis:intersects? road self]
  ask patches gis:intersecting road [set is-road? true]
  ask patches with [is-road? != true][set is-road? false]

 foreach gis:feature-list-of road [vector-feature ->
    ask patches [if gis:intersects? vector-feature self
      [ set traffic gis:property-value vector-feature "mtr_dcl"
        ;set pcolor scale-color pink traffic 0 10
      ]
    ]
  ]

  ; Draw the road
  gis:set-drawing-color 99
  gis:draw road .5

  output-print "Road set"

end

to set-nox-weight
    foreach gis:feature-list-of nox_weighting [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [
      set nox_weight gis:property-value vector-feature "emiweight"
      ]
 ]]

  ask patches with [nox_weight = 0 or nox_weight = nobody][set nox_weight 0]
  ask patches with [is-research-area?][
    if nox_weight = 0 [set nox_weight 1]
    if nox_weight = 1 [set nox_weight 1.15]
    if nox_weight = 2 [set nox_weight 1.20]
    if nox_weight = 3 [set nox_weight 1.25]
    if nox_weight = 4 [set nox_weight 1.30]
    if nox_weight = 5 [set nox_weight 1.40]

  ]

output-print "nox weighting added" ;;
end
;;-----------------------------------
;; Move agents to urban areas coded 20 or 21
to set-urban-areas
  foreach gis:feature-list-of lc [vector-feature ->
    ask patches [if gis:intersects? vector-feature self
                [let all-twenty-two-codes gis:property-value vector-feature "Code"
        if (all-twenty-two-codes = 20) or (all-twenty-two-codes = 21) [set is-built-area? true]
    ]]
 ]
 ask patches with [is-built-area? != true][set is-built-area? false]

 output-print "Land Cover Allocated" ;;
end

;;----------------------------
to set-monitor-location
  let stations gis:load-dataset "Data/London_AP_Stations.shp"

  set station_background (list  "BG1" "BG2" "BL0" "BQ7" "BX1" "BX2" "CT3" "EN1" "EN7" "GR4" "HG4" "HI0"
 "HR1" "IS6" "KC1" "LB6" "LH0" "LW1" "LW5" "NM3"  "RB7" "RI2" "SK6" "WA2" "WA9" "WM0")


  set station_road (list "BT4" "BT6" "BT8" "BY7" "CR5"
    "CT4" "CT6" "EA6" "EI1" "EN4" "EN5" "GB6" "GN0" "GN3" "GN5" "GN6" "GR7" "GR8" "GR9" "GV2"
    "HK6" "HV1" "HV3" "IM1" "IS2" "KT4" "KT5" "KT6" "LB4" "LW4" "MY1" "NB1" "NM2" "RB4" "RI1"
    "SK8" "ST4" "ST6" "TH4" "WAA" "WAB" "WAC" "WM6" "WMB" "WMC"
    )

let random-station one-of station_road
output-print word "the station that was removed is :"random-station


ifelse LOOCV?
[
  set station_road remove random-station station_road

]
[
  ;; Do something else if LOOCV? switch is off
  set station_road station_road
]

  foreach gis:feature-list-of stations [vector-feature ->
    let current_code gis:property-value vector-feature "code"

    ; Check if the current station's code is in the station_background list
    if member? current_code station_background [
      ask patches [ if gis:intersects? vector-feature self
        [ set is-monitor-site? true
          set monitor-name gis:property-value vector-feature "site"
          set monitor-code current_code
          set monitor-type gis:property-value vector-feature "site_type"
          set pcolor red + 2
        ]
      ]
    ]


    if member? current_code station_road [
      ask patches [ if gis:intersects? vector-feature self
        [ set is-monitor-site? true
          set monitor-name gis:property-value vector-feature "site"
          set monitor-code current_code
          set monitor-type gis:property-value vector-feature "site_type"
          set pcolor blue
        ]
      ]
    ]
    ]


  output-print "Station GIS location loaded"


  ask patches with [is-monitor-site? != true]
  [set monitor-name false set is-monitor-site? false set monitor-type false set monitor-code false]

end



to set-nearest-station
  ask patches with [
    is-research-area? = true and
    ;is-road? = false and
    is-monitor-site? = false and
    monitor-code = false and
    monitor-name = false ][
    set nearest_station min-one-of patches with [
      is-monitor-site? = true
    ] [distance myself]
  ]

end




;;;;;;;;;;;;
;; --go-- ;;
;;;;;;;;;;;;

to go
  generate-no2-background ;; in the .nls file
  generate-no2-road ;; in the .nls file
  generate-no2-patches
  ;export-no2
  export-no2-bs

  tick
  if ticks = 890 [ stop ]

end


to generate-no2-patches
  ask patches [
    if is-research-area? and
       not is-monitor-site? and
       monitor-code = false and
       monitor-name = false
    [
      let no2_interpolated (calculate-idw-no2 self)
      set no2 no2_interpolated * nox_weight
      set pcolor scale-color pink no2 0 100
    ]
  ]


  ask patches with [not is-built-area?][set no2 (no2 * 0.7)]

  ask patches with [monitor-type = "Urban Background" or monitor-type = "Suburban"] [
  let valid-neighbors neighbors4 with [not is-monitor-site?]
  set no2 one-of [no2] of valid-neighbors

]

end



to-report calculate-idw-no2 [target-patch]
  let total-weighted-value 0
  let total-weight 0

  ; Loop through each station
  ask patches with [is-monitor-site? and monitor-type = "Roadside" or monitor-type = "Kerbside"] [
    let avg_no2 mean [no2_list] of self

    let dist distance target-patch  ; Calculate the distance from the station to the patch
    if dist > 0 [  ; Avoid division by zero
      let weight 1 / (dist ^ 2)  ; Calculate the weight based on distance
      ;let avg_no2 mean no2  ; Calculate the average NO2 value for the station
      set total-weighted-value total-weighted-value + (avg_no2 * weight)
      set total-weight total-weight + weight
    ]
  ]

  ; Calculate the weighted average
  ifelse total-weight > 0 [
    report total-weighted-value / total-weight
  ] [
    report 0  ; Avoid division by zero, handle as you see fit
  ]
end



to export-no2
  let file-name "no2_export.csv"
  ;let list_roadstation ["BT4" "BT6" "BT8" "EI1" "GB6" "GN0" "GN3" "HV1" "HV3" "IS2" "KT6" "LW4" "RB4" "WMB"]
  let list_roadstation (list  "BG1" "BG2" "BL0" "BQ7" "BX1" "BX2" "CT3" "EN1" "EN7" "GR4" "HG4" "HI0"
 "HR1" "IS6" "KC1" "LB6" "LH0" "LW1" "LW5" "NM3"  "RB7" "RI2" "SK6" "WA2" "WA9" "WM0")

  ; Check if the file exists. If not, create it and write the header
  if not file-exists? file-name [
    file-open file-name
    file-write "tick, monitor_code, no2"
    file-print ""  ; Move to the next line
    file-close
  ]

    ; Append data to the file
  file-open file-name


  ; Loop through each patch in the research area and check if monitor-type is in the list
  ask patches with [is-road? and is-research-area?] [
    if member? monitor-code list_roadstation [
      file-print (word  ticks ", " monitor-code ", " no2)
    ]
  ]
  ; Close the file
  file-close

end

to export-no2-bs
  let file-name "no2_export.csv"
  let list_bgstation ["WA9" "LH0" "HG4" "SK6" "WA2" "WM0" "HR1" "LW5" "BL0" "BQ7" "CT3" "IS6" "NM3" "RB7" "EN7" "LB6" "KC1" "LW1"]

  ; Check if the file exists. If not, create it and write the header
  if not file-exists? file-name [
    file-open file-name
    file-write "tick, monitor_code, no2, no2_list"
    file-print ""  ; Move to the next line
    file-close
  ]

    ; Append data to the file
  file-open file-name


  ; Loop through each patch in the research area and check if monitor-type is in the list
  ask patches with [is-road? and is-research-area?] [
    if member? monitor-code list_bgstation [
      file-print (word  ticks ", " monitor-code ", " no2 ", " mean(no2_list))
    ]
  ]
  ; Close the file
  file-close

end


;;;;;;;;;;;;;;

to iterate-10-times
  repeat 10 [
    setup
    go-until-2921
  ]
end

to go-until-2921
  while [ticks < 890] [
    go
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
129
18
590
375
-1
-1
3.0
1
10
1
1
1
0
0
0
1
0
150
0
115
1
1
1
ticks
30.0

BUTTON
13
16
79
49
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
13
54
76
87
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

OUTPUT
604
17
848
170
12

BUTTON
14
94
77
127
step
go
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

SLIDER
604
184
767
217
roadpollution_weight
roadpollution_weight
0
1
0.5
0.1
1
NIL
HORIZONTAL

BUTTON
14
135
78
168
iterate
iterate-10-times
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

TEXTBOX
14
176
121
275
Go: Run the simulation once\nStep: just one tick\nIterate: Run the whole simulation for 10 times
9
0.0
1

TEXTBOX
142
329
259
369
NO2 Concentration (increase):\nDarker -> Pink -> White
9
0.0
1

SWITCH
604
230
712
263
LOOCV?
LOOCV?
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>no2_bs</metric>
    <steppedValueSet variable="roadpollution_weight" first="0" step="0.05" last="2"/>
  </experiment>
</experiments>
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
