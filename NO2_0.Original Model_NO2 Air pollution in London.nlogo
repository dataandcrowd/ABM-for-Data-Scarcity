extensions [gis csv table]
globals [gu road lc districtPop districtadminCode %riskpop date where hosp_1564 poll_scenario additional_pm25 hosp_u15 hosp_ov65 hosp_1564new hosp_u15new hosp_ov65new
         pm2.5_Marylebone pm2.5_Westminster  pm2.5_Camden ;; roadside/kerbside stations
         pm2.5_NKensington pm2.5_Bloomsbury pm2.5_HonorOakPark pm2.5_Bexley pm2.5_Teddington pm2.5_Eltham ;; background stations
         pm2.5_Harlington ;; for intercity commuters (moving back and from max pxcor max pycor)
         inner_south inner_north inner_ncentre outer_west outer_east
         danger age15 age1564 age65 scenario_counter scenario_date]
breed [borough-labels borough-label]
patches-own [is-research-area? is-built-area? name homecode
  is-monitor-site? monitor-name monitor-code monitor-type pm2.5]


;;--------------------------------
to setup
 clear-all
 file-close-all ; Close any files open from last run
 reset-ticks
 set-gis-data
 set-urban-areas
 set-district-division
 set-monitor-location
 add-labels
 add-admin

 add-pollution
end
;;---------------------------------
to go
  update-interface
  calc-pm10
  visual-effect
  tick
  if (ticks = 2922) [stop]
end


;;--------------------------------
to set-gis-data
  ask patches [set pcolor white]
  gis:load-coordinate-system (word "Data/London_Boundary_cleaned.prj")
  set gu   gis:load-dataset "Data/London_Boundary_cleaned.shp"
  set lc   gis:load-dataset "Data/London_LandCover.shp"
  set road gis:load-dataset "Data/London_Road_Clean.shp"

  gis:set-world-envelope (gis:envelope-union-of gis:envelope-of gu)
  ask patches gis:intersecting gu [set is-research-area? true]
;;--------------------------------



;;--------------------------------
  ;; Draw district
;foreach gis:feature-list-of gu [ gu-feature ->
;    gis:set-drawing-color scale-color green (gis:property-value gu-feature "index") 1 33
;    gis:fill gu-feature 0
;  ]
  gis:set-drawing-color [64  64  64]    gis:draw gu 1
  gis:set-drawing-color 7    gis:draw road 1
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
 ask patches with [is-built-area? = false and name = "Bexley"][set is-built-area? true] ;; for some reason Bexley wasn't added

 output-print "Land Cover Allocated" ;;
end

;;--------------------------------
to add-labels
  foreach gis:feature-list-of gu [vector-feature ->
  let centroid gis:location-of gis:centroid-of vector-feature
       if not empty? centroid
      [ create-borough-labels 1
        [ set xcor (item 0 centroid + 10) ;; added an arbitrary number due to the indented name setting
          set ycor item 1 centroid
          set size 2
          set label-color blue
          set label gis:property-value vector-feature "NAME"
        ]]]
end
;;--------------------------------
to add-admin
  gis:set-drawing-color blue
  foreach gis:feature-list-of gu [vector-feature ->
    ask patches[ if gis:intersects? vector-feature self [set name gis:property-value vector-feature "NAME"
                                 set homecode gis:property-value vector-feature "GSS_CODE"]
 ]]
output-print "Admin area added" ;;
end

;;--------------------------------
to set-district-division

  set inner_south (list "Southwark" "Lambeth" "Wandsworth" "Lewisham")
  set inner_north (list "Hammersmith and Fulham" "Kensington and Chelsea" "Haringey" "Tower Hamlets" "Newham")
  set inner_ncentre (list "Westminster" "Camden" "Islington" "Hackney")
  set outer_west (list "Enfield" "Waltham Forest" "Barnet" "Brent" "Harrow" "Ealing" "Hounslow" "Hillingdon"
  "Richmond upon Thames" "Kingston upon Thames" "Merton" "Sutton")
  set outer_east (list "Waltham Forest" "Redbridge" "Barking and Dagenham" "Havering" "Greenwich" "Bexley"
  "Bromley" "Croydon")

  output-print "set-district-division added"
end

;;----------------------------
to set-monitor-location

  let stations gis:load-dataset "Data/London_AP_Stations.shp"

  foreach gis:feature-list-of stations [vector-feature ->
   ask patches[ if gis:intersects? vector-feature self
      [ set is-monitor-site? true
        set monitor-name gis:property-value vector-feature "site"
        set monitor-code gis:property-value vector-feature "code"
        set monitor-type gis:property-value vector-feature "site_type"
        set pcolor red + 2
        ]
    ]
  ]

  ask patches with [is-monitor-site? != true]
  [set monitor-name false set is-monitor-site? false set monitor-type false set monitor-code false]

end



;;--------------------------------


to add-pollution
; Import daily pollution
  let airqualityfile csv:from-file "Data/London_AQ.csv"
  let airqualityfile_headerremoved remove-item 0 airqualityfile
  let rep 0
  ;;set pm2.5data table:make
  set pm2.5_Marylebone table:make
  set pm2.5_Westminster table:make
  set pm2.5_Camden table:make
  set pm2.5_NKensington table:make
  set pm2.5_Bloomsbury table:make
  set pm2.5_HonorOakPark table:make
  set pm2.5_Bexley table:make
  set pm2.5_Teddington table:make
  set pm2.5_Eltham table:make
  set pm2.5_Harlington table:make

  foreach airqualityfile_headerremoved [ station ->
    if item 2 station = "London Marylebone Road" [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Marylebone counter the-rest]
    if item 2 station = "London Westminster"     [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Westminster counter the-rest]
    if item 2 station = "London Bexley"          [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Bexley counter the-rest]
    if item 2 station = "London Eltham"          [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Eltham counter the-rest]
    if item 2 station = "Camden Kerbside"        [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Camden counter the-rest]
    if item 2 station = "London N. Kensington"   [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_NKensington counter the-rest]
    if item 2 station = "London Bloomsbury"      [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Bloomsbury counter the-rest]
    if item 2 station = "London Harlington"      [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Harlington counter the-rest]
    if item 2 station = "London Honor Oak Park"  [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_HonorOakPark counter the-rest]
    if item 2 station = "London Teddington Bushy Park" [let counter item 0 station let the-rest remove-item 0 station table:put pm2.5_Teddington counter the-rest]
  ]
set rep rep + 1


  let list_of_districts (list "Barking and Dagenham" "Havering" "Hillingdon" "Richmond upon Thames" "Bexley"
    "Bromley" "Brent" "Greenwich" "Harrow" "Enfield" "Sutton" "Merton" "Barnet" "Newham" "Camden" "Ealing"
    "Redbridge" "Croydon" "Southwark" "Tower Hamlets" "Haringey" "Wandsworth" "Waltham Forest" "Lewisham" "Hounslow" "Hackney"
    "Kingston upon Thames" "Hammersmith and Fulham" "Westminster" "Lambeth" "Islington" "Kensington and Chelsea" "City of London")
 output-print "air pollution installed"
end


to update-interface
  set date item 0 table:get pm2.5_Westminster (ticks + 1)
  set where item 2 table:get pm2.5_Westminster (ticks + 1)

end


;;;;;;;;;;;;;;;;;;;;;;;;;;
to calc-pm10
  ;set inner_south (list "Southwark" "Lambeth" "Wandsworth" "Lewisham")
  ;set inner_north (list "Hammersmith and Fulham" "Kensington and Chelsea" "Haringey" "Tower Hamlets" "Newham")
  ;set inner_ncentre (list "Westminster" "Camden" "Islington" "Hackney")
  ;set outer_west (list "Enfield" "Waltham Forest" "Barnet" "Brent" "Harrow" "Ealing" "Hounslow" "Hillingdon"
  ;"Richmond upon Thames" "Kingston upon Thames" "Merton" "Sutton")
  ;set outer_east (list "Waltham Forest" "Redbridge" "Barking and Dagenham" "Havering" "Greenwich" "Bexley" "Bromley" "Croydon")

  let theloop 0
    foreach inner_south [sdistricts -> ask patches with [name = sdistricts][if ticks > 0 [set-inner_south]]]
    foreach inner_north [ndistricts -> ask patches with [name = ndistricts][if ticks > 0 [set-inner_north]]]
    foreach inner_ncentre [incentre -> ask patches with [name = incentre][if ticks > 0 [set-inner_centre]]]
    foreach outer_west [outerwest -> ask patches with [name = outerwest][if ticks > 0 [set-outer_west]]]
    foreach outer_east [outereast -> ask patches with [name = outereast][if ticks > 0 [set-outer_west]]]
  set theloop theloop + 1

  ask patch max-pxcor max-pycor[if ticks > 0 [set-intercity]]


end


to set-inner_south
  let homeID item (3 + random 13) table:get pm2.5_HonorOakPark ticks + 1
  let workID item (3 + random 11) table:get pm2.5_HonorOakPark ticks + 1

  if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_HonorOakPark ticks + 1]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_HonorOakPark ticks + 1]]

  if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_HonorOakPark ticks + 1) * 0.60]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_HonorOakPark ticks + 1) * 0.60]]

  ;additional_pm25

end

to set-inner_north
  let homeID item (3 + random 13) table:get pm2.5_NKensington ticks + 1
  let workID item (3 + random 11) table:get pm2.5_NKensington ticks + 1

  if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_NKensington ticks + 1]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_NKensington ticks + 1]]

  if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_NKensington ticks + 1) * 0.60]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_NKensington ticks + 1) * 0.60]]
  end

to set-inner_centre
  let homeID item (3 + random 13) table:get pm2.5_Bloomsbury ticks + 1
  let workID item (3 + random 11) table:get pm2.5_Bloomsbury ticks + 1

  if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_Bloomsbury ticks + 1]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_Bloomsbury ticks + 1]]

  if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_Bloomsbury ticks + 1) * 0.60]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_Bloomsbury ticks + 1) * 0.60]]

end

to set-outer_west
  let homeID item (3 + random 13) table:get pm2.5_Teddington ticks + 1
  let workID item (3 + random 11) table:get pm2.5_Teddington ticks + 1

  if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_Teddington ticks + 1]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_Teddington ticks + 1]]

  if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_Teddington ticks + 1) * 0.60]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_Teddington ticks + 1) * 0.60]]


end

to set-outer_east
  let homeID item (3 + random 13) table:get pm2.5_Teddington ticks + 1
  let workID item (3 + random 11) table:get pm2.5_Teddington ticks + 1

  if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_Eltham ticks + 1]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_Eltham ticks + 1]]

  if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_Eltham ticks + 1) * 0.60]]
  if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_Eltham ticks + 1) * 0.60]]

end


to set-intercity
  let homeID item (3 + random 13) table:get pm2.5_Harlington ticks + 1
  let workID item (3 + random 11) table:get pm2.5_Harlington ticks + 1

   if (ticks + 1) mod 2 = 0 [ifelse homeID > 0 [set pm2.5 homeID][set pm2.5 max table:get pm2.5_Harlington ticks + 1]]
   if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID][set pm2.5 max table:get pm2.5_Harlington ticks + 1]]

   if (ticks + 1 mod 2 = 0) [ifelse homeID > 0 [set pm2.5 homeID * 0.60][set pm2.5 (max table:get pm2.5_Harlington ticks + 1) * 0.60]]
   if ticks       mod 2 = 0 [ifelse workID > 0 [set pm2.5 workID * 0.60][set pm2.5 (max table:get pm2.5_Harlington ticks + 1) * 0.60]]


end


to visual-effect
  ask patches [ifelse (pm2.5 > 0)
    [set pcolor scale-color green pm2.5 40 0]
    [set pcolor white]
  ]


end
@#$#@#$#@
GRAPHICS-WINDOW
421
111
880
466
-1
-1
1.5
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
300
0
230
1
1
1
half day
30.0

BUTTON
18
21
101
54
1.Setup
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
18
57
101
90
2. Go
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

TEXTBOX
573
79
759
105
London Health Sim
18
0.0
1

MONITOR
108
23
200
68
Date
date
17
1
11

MONITOR
204
23
273
68
Location
where
17
1
11

PLOT
15
151
394
271
PM2.5 patches
time
pm2.5
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Southwark" 1.0 0 -13840069 true "let southwark_plot [pm2.5] of one-of patches with [name = \"Southwark\"]" "plot [pm2.5] of one-of patches with [name = \"Southwark\"]"
"pen-1" 1.0 0 -7500403 true "" "plot [pm2.5] of one-of patches with [name = \"Lambeth\"]"
"pen-2" 1.0 0 -2674135 true "" "plot [pm2.5] of one-of patches with [name = \"Wandsworth\"]"
"pen-3" 1.0 0 -955883 true "" "plot [pm2.5] of one-of patches with [name = \"Lewisham\"]"
"pen-4" 1.0 0 -6459832 true "" "plot [pm2.5] of one-of patches with [name = \"Hammersmith and Fulham\"]"
"pen-5" 1.0 0 -1184463 true "" "plot [pm2.5] of one-of patches with [name = \"Kensington and Chelsea\"]"
"pen-6" 1.0 0 -10899396 true "" "plot [pm2.5] of one-of patches with [name = \"Haringey\"]"
"pen-7" 1.0 0 -14835848 true "" "plot [pm2.5] of one-of patches with [name = \"Tower Hamlets\"]"
"pen-8" 1.0 0 -11221820 true "" "plot [pm2.5] of one-of patches with [name = \"Newham\"]"
"pen-9" 1.0 0 -13791810 true "" "plot [pm2.5] of one-of patches with [name = \"Westminster\"]"
"pen-10" 1.0 0 -13345367 true "" "plot [pm2.5] of one-of patches with [name = \"Camden\"]"
"pen-11" 1.0 0 -8630108 true "" "plot [pm2.5] of one-of patches with [name = \"Islington\"]"
"pen-12" 1.0 0 -5825686 true "" "plot [pm2.5] of one-of patches with [name = \"Hackney\"]"
"pen-13" 1.0 0 -2064490 true "" "plot [pm2.5] of one-of patches with [name = \"Enfield\"]"
"pen-14" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Waltham Forest\"]"
"pen-15" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Barnet\"]"
"pen-16" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Brent\"]"
"pen-17" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Harrow\"]"
"pen-18" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Ealing\"]"
"pen-19" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Hounslow\"]"
"pen-20" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Hillingdon\"]"
"pen-21" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Richmond upon Thames\"]"
"pen-22" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Kingston upon Thames\"]"
"pen-23" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Merton\"]"
"pen-24" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Sutton\"]"
"pen-25" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Waltham Forest\"]"
"pen-26" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Redbridge\"]"
"pen-27" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Barking and Dagenham\"]"
"pen-28" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Havering\"]"
"pen-29" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Greenwich\"]"
"pen-30" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Bexeley\"]"
"pen-31" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Bromley\"]"
"pen-32" 1.0 0 -16777216 true "" "plot [pm2.5] of one-of patches with [name = \"Croydon\"]"

OUTPUT
15
281
395
413
12

BUTTON
16
97
103
130
3. Go Ticks
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

@#$#@#$#@
## WHAT IS IT?
**SIMULATING PEDESTRIAN EXPOSURE TO AMBIENT URBAN AIR POLLUION**

The model’s objective is to understand the cumulative effects on the population’s vulnerability as represented by exposure to PM10 (particulate matter with diameter less than 10 micrometres) by different age and educational groups in Gangnam. Using this model, readers can explore individual's daily commuting routine, and its health loss when the PM10 concentration of the current patch breaches the national limit.

The model is initialised with a starting population with no previous exposure, in other words every agents have health of 300 in the beginning. This is because we couldn't find reliable references or statistics to access individual health reports.

## HOW IT WORKS
*Number of agents*. We used a 1% sample of Gangnam's total population, which was retrieved from the census website, rounded to a total of 5050 agents waiting for simulation. Agents aged under 15 are coloured in orange, between 15 and 64 are in turquoise, and over 65 in brown.

*Set destination*. During the setup process, every agent is assigned a fixed home name (sub-district) and home patch as well as their destination name and patch. In addition, agents will have their destination names and patches but differ by age groups. Agents between *age 15 and 65*, so called the economically active population, will move to their destination patches according to the fraction in the origin-destination (OD) matrix. Those who commute to other districts are assigned as *others*, and are allocated to patches outside Gangnam during working hours. Agents *aged under 15* will move to a random patch within 3 radius, while those *aged over 65* will move to a random patch within 1 radius. Given that the model is a simplified version, the model was designed to move agents in two phases: move-out and come-home.

*Health loss*. With initial health of 300, each agent will be located within their residential patch and be exposed to the patches at which they are stepping on. When the model activates, agents will move back and forth to their home destination patches. An agent will lose health when  exposed to a patch exceeding the PM10 concentration of 50, 100, or 150 μg/m3. Once the agent's health goes below 200, its colour will change to violet, then to red when it goes below 100. While the district plot captures both agents coloured in violet and red, the other plots capture agents only coloured in red. Even without pollution, people's health naturally aggravate over time, depending on age groups. Indeed, this model is not designed to kill people due to a short simulation period of 6 years. However, the interest here is to investigate health variances between groups and sub-regions.

*Health recovery* There is also a recovery mode that heals people's health. We selected land price as a representative factor for remedy. We assumed that hospitals and clinics in Seoul locate in costly areas, which therefore creates better opportunities to nearby residents to visit the doctor when needed.

*Expected outcomes*. This model expects four different outcomes. First plot is the total percentage of risk population in Gangnam. Second plot is the total percentage of risk population by subdistrict level. Third plot is the total percentage of risk population by age groups, followed by the last plot by education groups.

*Simulation time*. The model estimates the dynamic change (vulnerability) of the risk population by socioeconomic factors, and district for 6 years (4381 ticks) for which we have pollution data.


## HOW TO USE IT
**SIMPLE**: Press setup and go to run the model. The model would not stop until the total risk population exceeds 90% or the calendar date reaches the 31st of December 2015. If you would like to know the background information, keep on reading!

### Setup
*GIS DATA*: We imported GIS data of administrative boundary, road networks, land price, and a daily-mean interpolation map of PM10 all in ASCII format.

*ATTRIBUTE DATA*: We imported attributes from the 2010 Korean census of Gangnam in sub-district level by age and education status. Also, daily pollution statistics, provided by the national institution for environmental research (NIER), were cleaned and aggregated to office and home hours. We defined office hours from 9am to 7pm, and the remainder to home hours. For atmospheric settings, each patch contains its own daily average value of PM10 in the beginning, and changes its value over time according to its daily pollution statistics.

### Parameter settings
*AC*: These scenarios impose “adaptive capacity” on the maximum health for the whole population of 100, 150, and 200. Compared to scenario 100, scenario 200 means that the population has more capacity to accumulate resilience when pollution levels remain low.

*Scenario*: The pollution scenario consists of 3 types: business as usual (BAU), assuming the pollution trend as per the statistics continues for 6 years; increase (INC), where an addition of 15% of BAU is added everyday; and decrease (DEC), an 15% of BAU is degraded everyday.

*PM10 parameter*: We chose parameters to correspond different daily standards in various countries, where EU/UK in 50μg/m3, South Korea in 100μg/m3, and US in 100μg/m3.

### Monitors
*%riskpop* counts the total population coloured in red
*Date*: Actual date of pollution provided
*Where* is the current location of agents

## THINGS TO NOTICE
One tick is a half a day.
Agents will jump to their destinations and origins.
Agents who are assigned as *others* are inter-district commuters, but move to the far east corner for simplicity.
## THINGS TO TRY
Use different PM10 parameters and see the temporal difference.
Apply Scenarios.


## EXTENDING THE MODEL
We are planning to combine this model to a traffic model that takes into account exposures to tailpipe emission.

## NETLOGO FEATURES
(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS
UrbanSuite - Pollution

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="cali" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 2300</exitCondition>
    <metric>%riskpop</metric>
    <metric>hosp_u15</metric>
    <metric>hosp_1564</metric>
    <metric>hosp_ov65</metric>
    <enumeratedValueSet variable="Scenario">
      <value value="&quot;BAU&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AC">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PM2.5-Parameter">
      <value value="25"/>
    </enumeratedValueSet>
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
