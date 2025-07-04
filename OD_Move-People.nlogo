;__includes["csv_import_NO2background.nls" "csv_run_NO2background.nls"]

extensions [csv gis table ]
globals [
  ;;; Admin
  borough road IMD lc visit
  districtPop districtadminCode
  station_background
  clock
  place-to-visit-age
  central
]

breed [borough-labels borough-label]
breed[people person]

patches-own [is-research-area? is-built-area? central-London? is-road? name homecode visiting? visiting-borough?
  ;is-monitor-site? monitor-name monitor-code monitor-type ;nearest_station no2 ;; pollution related
  IMDrank
  ;hospital
]
people-own  [health age districtName district-code
             homeName homePatch destinationName destinationPatch central-Londoner?
             weekend-shopper?
             place-to-visit visit-location
   ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to setup
  clear-all
  file-close-all
  reset-ticks
  set-gis-data
  set-urban-areas
  set-visit-places
  set-date-clock
  add-admin
  add-IMD
  set-dictionaries
  set-people
  set-destination
  remove-young-old

end

to set-gis-data
  ask patches [set pcolor white]
  gis:load-coordinate-system (word "Data/London_Boundary_cleaned.prj")
  set borough   gis:load-dataset "Data/London_Boundary_cleaned.shp"
  set lc   gis:load-dataset "Data/London_LandCover.shp"
  set road gis:load-dataset "Data/London_Road_Clean.shp"
  set visit gis:load-dataset "Data/SpacesToVisit.shp"
  set IMD gis:load-dataset "Data/IMD2019_LocalAuthority_Upper.shp"
  set central gis:load-dataset "Data/central_activities_zone.shp"
  ;; patch size: approx 200m x 200m

  let base_envelope gis:envelope-of borough

  let span_x abs ( item 0 base_envelope - item 1 base_envelope )
  let span_y abs ( item 2 base_envelope - item 3 base_envelope )
  let alternating_spans ( list span_x span_x span_y span_y )
  let alternating_signs [ -1 1 -1 1 ]

  let expanded_envelope (
    map [ [ i span sign ] -> i + sign * ( 0.05 * span )  ]
    base_envelope alternating_spans alternating_signs
  )

  gis:set-world-envelope expanded_envelope

  ;gis:set-world-envelope (gis:envelope-union-of gis:envelope-of borough)
  ask patches gis:intersecting borough [set is-research-area? true]
  ask patches gis:intersecting road [set is-road? true]
  gis:set-drawing-color [64  64  64]    gis:draw borough 1
  gis:set-drawing-color 7    gis:draw road 1

  ask patches with [is-research-area? != true][set is-research-area? false set name false set homecode false]
  ask patches with [is-road? != true][set is-road? false]

  output-print "Road set"

  ;; add GIS labels

  foreach gis:feature-list-of borough [vector-feature ->
  let centroid gis:location-of gis:centroid-of vector-feature
       if not empty? centroid
      [ create-borough-labels 1
        [ set xcor (item 0 centroid + 1) ;; added an arbitrary number due to the indented name setting
          set ycor item 1 centroid
          set size 0 ;; to hide the shape of the turtles
          set label-color blue
          set label gis:property-value vector-feature "NAME"
        ]]]
end


to add-admin
  gis:set-drawing-color blue
  foreach gis:feature-list-of borough [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [set name gis:property-value vector-feature "NAME"
                                 set homecode gis:property-value vector-feature "GSS_CODE"]
 ]]
output-print "Admin area added" ;;
end

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

;;--------------------------------

to set-visit-places
  foreach gis:feature-list-of visit [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [
                 set visiting? gis:property-value vector-feature "PrimaryUse"
                 set visiting-borough? gis:property-value vector-feature "Borough"
      ]
 ]]

  ask patches with [visiting? = 0][set visiting? false]


  foreach gis:feature-list-of visit [vector-feature ->
    ask patches [if gis:intersects? vector-feature self [
      set central-London? true
  ]]]

  ask patches with [central-London? != true][set central-London? false]

 output-print "Visiting Place Assigned" ;;
end

;;--------------------------------
to add-IMD
  gis:set-drawing-color blue
  foreach gis:feature-list-of IMD [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [set IMDrank gis:property-value vector-feature "RAvgRank"]
 ]]

  ;; Rank close to 1 (more deprived), Rank with higher numbers (Less deprived)
  ;; if rank 5-11: +1
  ;; if rank 12-47: +5
  ;; if rank 48-87: +10
  ;; if rank 88-123: +20
  ;; if rank 124-148: +40

output-print "Deprivation Index added" ;;
end


to set-date-clock
  let clock-raw csv:from-file "Data/date2019.csv"
  let clock-rm-raw remove-item 0 clock-raw
  set clock table:make

  foreach clock-rm-raw [code ->
    let date1 list(item 1 code)(item 2 code)
    let date2 lput item 3 code date1
    table:put clock item 0 code date2

  ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-dictionaries
  let csv-age-raw csv:from-file "Data/London_Census_chun.csv"
  let csv-age remove-item 0 csv-age-raw
  set districtpop table:make
  set districtadminCode table:make

  foreach csv-age [ code ->
  let age59 list (item 3 code) (item 4 code)
     let age1014 lput item 5 code age59
     let age1519 lput item 6 code age1014
     let age2024 lput item 7 code age1519
     let age2529 lput item 8 code age2024
     let age3034 lput item 9 code age2529
     let age3539 lput item 10 code age3034
     let age4044 lput item 11 code age3539
     let age4549 lput item 12 code age4044
     let age5054 lput item 13 code age4549
     let age5559 lput item 14 code age5054
     let age6064 lput item 15 code age5559
     let age6569 lput item 16 code age6064
     let age7074 lput item 17 code age6569
     let age7579 lput item 18 code age7074
     let age8084 lput item 19 code age7579
     let age8589 lput item 20 code age8084 ;; actually this the column age > 90

     table:put districtpop item 1 code age8589
     table:put districtadminCode item 1 code item 0 code
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-people
  foreach table:keys districtpop [ dist ->
    let ageGroupID 0
    foreach table:get districtpop dist [ number ->
      create-people number [
        setupAgeGroup agegroupID
        set districtName dist
        set district-code table:get districtadminCode dist
        set shape "person"
        set heading random 360
        set homeName dist
        set homePatch one-of patches with [homecode = [district-code] of myself and is-built-area? = true]
        move-to homePatch
        set destinationName "unidentified"
        set destinationPatch "unidentified"
        ifelse random-float 1 < 0.1 [set weekend-shopper? true][set weekend-shopper? false]
        ifelse patch-here = central-London? [set central-Londoner? true][set central-Londoner? false]
      ]
      set ageGroupID AgeGroupID + 1
      ]
  ]
end

to setupAgeGroup [ID]
if ID = 0  [set size 1 set age  5 + random 5 set health 300 - (0.071 * (10 + random 30)) set color orange]
if ID = 1  [set size 1 set age 10 + random 5 set health 300 - (0.061 * (10 + random 30)) set color orange + 1]
if ID = 2  [set size 1 set age 15 + random 5 set health 300 - (0.111 * (10 + random 30)) set color orange + 2]
if ID = 3  [set size 1 set age 20 + random 5 set health 300 - (0.185 * (10 + random 30)) set color turquoise]
if ID = 4  [set size 1 set age 25 + random 5 set health 300 - (0.233 * (10 + random 30)) set color turquoise]
if ID = 5  [set size 1 set age 30 + random 5 set health 300 - (0.233 * (10 + random 30)) set color turquoise]
if ID = 6  [set size 1 set age 35 + random 5 set health 300 - (0.217 * (10 + random 30)) set color turquoise]
if ID = 7  [set size 1 set age 40 + random 5 set health 300 - (0.224 * (10 + random 30)) set color brown]
if ID = 8  [set size 1 set age 45 + random 5 set health 300 - (0.294 * (10 + random 30)) set color brown]
if ID = 9  [set size 1 set age 50 + random 5 set health 300 - (0.342 * (10 + random 30)) set color brown]
if ID = 10 [set size 1 set age 55 + random 5 set health 300 - (0.409 * (10 + random 30)) set color brown]
if ID = 11 [set size 1 set age 60 + random 5 set health 300 - (0.539 * (10 + random 30)) set color violet]
if ID = 12 [set size 1 set age 65 + random 5 set health 300 - (0.853 * (10 + random 30)) set color violet]
if ID = 13 [set size 1 set age 70 + random 5 set health 300 - (0.956 * (10 + random 30)) set color violet]
if ID = 14 [set size 1 set age 75 + random 5 set health 300 - (1.413 * (10 + random 20)) set color violet]
if ID = 15 [set size 1 set age 80 + random 5 set health 300 - (2.059 * (10 + random 20)) set color pink]
if ID = 16 [set size 1 set age 85 + random 15 set health 300 - (3.034 * (10 + random 20)) set color pink]

end


;;;;;;;;;;;;;;;;;;;;;
to set-destination   ;; Decomposing matrix
  let odcsv csv:from-file "Data/London_OD.csv"
  let rawheader item 0 odcsv
  let destinationNames remove-item 0 rawheader
  let Mat remove-item 0 odcsv

  let loopnum 1
  let Matrix table:make ;; This is a matrix where each origin has its name as a "key"
  foreach Mat [ origin-chart ->
    let numberMat remove-item 0 origin-chart    ;; fraction has to be btw 0-1,
    let fraction map [ i -> i / 100 ] numberMat ;; but the original file is btw 1-100
    table:put Matrix item 0 origin-chart fraction
                 ]
  set loopnum loopnum + 1

  foreach table:keys Matrix [ originName ->
    let matrix-loop 0
    let Num count people with [homeName = originName and (age >= 16 and age < 65)]
    let totalUsed 0
    let number 0

	foreach table:get Matrix originName
       [ percent ->
          let newDestination item matrix-loop destinationNames ;; Let agents of 32 origins choose their destinations
          ifelse (newDestination != "others") [set number precision (percent * Num) 0 set totalUsed totalUsed + number]
              [set number Num - totalUsed ]
		  ;; if agents move within district, then count agents by rounding the values of population x
      ;; "fraction of region A", population x "fraction of region B"...
      ;; if agents move outside district, then count the remainder of the population not used for inbound population
         let peopleRemaining (people with [homeName = originName and destinationName = "unidentified"
                and (age >= 16 and age < 65)])
         if count peopleRemaining > 0 and count peopleRemaining <= number [ set number count peopleRemaining ]
               if number < 0 [ set number 0]

         ask n-of number peopleRemaining [
                set destinationName newDestination ;; assign destination name
                set destinationPatch one-of patches with [name = newDestination and is-built-area? = true]
       ]
    set matrix-loop matrix-loop + 1
  ]
  type totalused type " " type Num type " " print originName ;; print inbound agents out of the total population (age 15-64)
  ]


;; Send agents selected as "others" to the NE corner
 ask people [ if destinationName = "others"
             [ set destinationPatch patch max-pxcor max-pycor]
             ]

 ask people with [destinationpatch = "unidentified" and age < 15]
                 [set destinationName homeName
                  set destinationPatch one-of patches in-radius 3] ;; Under 15
 ask people with [destinationpatch = "unidentified" and age >= 65]
                 [set destinationName homeName
                  set destinationPatch one-of patches in-radius 1] ;; Over 65

 output-print "People without destinations(nobody)"
 let wordloop 0
 foreach destinationNames [ dn ->
    print word (word(word (word dn ": ") count people with
    [homename = dn and destinationPatch = nobody] ) " out of " ) count people with
    [homename = dn ]
       ]
 set wordloop wordloop + 1


 ask people with [destinationname = "unidentified"][die] ;; We inevitably had to delete 8 agents from the City of London
  output-print "Set OD matrix" ;;
end


to remove-young-old
  ask people with [age < 16 or age >= 65][die]

end


;;;;;;;;;;;;
;; --go-- ;;
;;;;;;;;;;;;

to go

  move-places

  tick
  if ticks = 730 [stop]

end

;;---------------------------------

to move-places
  ask people [
  ifelse (ticks mod 2 = 0) or (ticks >= 208 and ticks <= 231) or (ticks > 710) [
    if (item 2 table:get clock ticks = "Weekday") [commute]
    if (item 2 table:get clock ticks = "Weekend") [hangout]
  ][come-home]
  ]
end

to commute
  if patch-here != destinationPatch [ move-to destinationPatch fd 1]
end

to come-home
  if patch-here != homePatch [move-to homePatch fd 1]
end

to hangout
   if random-float 1 < 0.75 [
    ifelse (weekend-shopper? = true) and (central-Londoner? = false)
    [set visit-location one-of patches with [visiting? = "Common" and central-London? = true]
     set place-to-visit "Central London"][update-visit-place]
     if visit-location != 0 [move-to visit-location]
  ]

end


to update-visit-place

    if age >= 16 and age <= 30 [
      set place-to-visit one-of ["Park" "Amenity green space" "Recreation ground" "Nature reserve"
                                 "Common" "Public woodland" "Play space" "Other recreational"
                                 "Walking/cycling route" "Adventure playground" "Youth area"
                                 "Landscaping around premises" "Formal garden"
                                 "Civic/market square"]

    ]
    if age > 30 and age <= 45 [
      set place-to-visit one-of ["Park" "Amenity green space" "Recreation ground" "Nature reserve"
                                 "Common" "Public woodland" "Other recreational"
                                 "Walking/cycling route" "Landscaping around premises"
                                 "Formal garden" "Play space" "Recreation ground"
                                 "City farm" "Allotments" "Civic/market square"]

    ]
    if age > 45 and age <= 65 [
      set place-to-visit one-of ["Park" "Amenity green space" "Recreation ground" "Nature reserve"
                                 "Common" "Public woodland" "Allotments" "Walking/cycling route"
                                 "City farm" "Village green" "Community garden"
                                 "Formal garden" "Civic/market square"]

    ]
    if age > 65 [
      set place-to-visit one-of ["Park" "Amenity green space" "Recreation ground" "Nature reserve"
                                 "Common" "Public woodland" "Village green" "Community garden"]
    ]


    let destination-patch min-one-of patches with [visiting? = [place-to-visit] of myself] [distance myself]

  if destination-patch != nobody [
    set visit-location destination-patch
  ]



end
@#$#@#$#@
GRAPHICS-WINDOW
108
24
569
381
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
24
848
174
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

MONITOR
603
220
697
265
Date (y-m-d)
item 0 table:get clock ticks
17
1
11

MONITOR
700
220
787
265
Home/Work
item 1 table:get clock ticks
17
1
11

MONITOR
602
272
698
317
Weekday/end
item 2 table:get clock ticks
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
