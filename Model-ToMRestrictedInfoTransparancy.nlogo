extensions [ csv
  table ]

globals [
  activity-list
  value-list
  competence-list
  affordance-list
  persontype-list
  i
  location
  numcarpoolers
  meanbeliefshift
  AllStudents_TotalTickChangeBel
  InfluencedStudents
  PercInfluenced
  bike-students
  license-percentage
  #Cars
  SocialGroupSA
  mean_TotalTickChangeBel
  busshare
  bikeshare
  carshare

  ;; variables for making a heatmap
  zero
  one
  two
  three
  four
  five
  six
  seven
  eight
  nine
]

breed [activities activity]
breed [competences competence]
breed [values value]
breed [affordances affordance]
breed [students student]

turtles-own [
  name
  totalvaluestrength
  new_totalval
  target-value
  car?
  license?
  implement
  candidate
  requirements
  belongings
  not-option
  chosen
  FileName
  personalvalues
  bikebeliefs
  carbeliefs
  busbeliefs
  BIbeliefs
  Cbeliefs
  BUbeliefs
  personalval-list
  ProSocial
  driving
  drivers
  partnerup
  traveltogether
  driveoption
  c
  p
  weights
  actnumber
  Enjoyment
  Stress
  CarIsOption
  maxcarpoolers
  carsfull-impossible
  SocialDifferences
  specificvalues
  like-minded
  correspondingbeliefs
  influencenumber
  satisfaction
  IntraPersonalComp
  SocialComp
  IntraPersSat
  StressEnjoyDifference
  AverageSocialDiff
  iterate
  iterate_val
  iterate_act
  ToM
  originalbikebeliefs
  originalcarbeliefs
  originalbusbeliefs
  TotalBeliefChangeBike
  TotalBeliefChangeCar
  TotalBeliefChangeBus
  TotalBeliefChange
  TickChangeBikeBel
  TickChangeCarBel
  TickChangeBusBel
  TotalTickChangeBel
  finalbikebelief
  finalcarbelief
  finalbusbelief
  PriviousBikeBel
  PriviousCarBel
  PriviousBusBel
  oldbikebel
  oldcarbel
  oldbusbel
  plot_belief
  focusagent
  targetagent
  BeliefDifference
  sdv
  history
  TotalEnjoyment
  TotalStress
  SociallyInfluenced
  InitialBeliefs
  FinalBeliefs
  BeliefShift
  SocialGroup

  ;;ToM-related variables
  overestimator
  ToM-deviation
  ExtraMean
  adjustedbeliefs
  predictedbeliefs
]

undirected-link-breed [Act-strengths Act-strength]
undirected-link-breed [Stud-strengths Stud-strength]
undirected-link-breed [has-competences has-competence]
undirected-link-breed [has-affordances has-affordance]
undirected-link-breed [relations relation]

Stud-strengths-own [value-strength
new-valuestr]

Act-strengths-own [value-strength
preference]

Relations-own [influencestrength]


;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-globals
  setup-values
  setup-students
  SetFileName
  setup-activities
  setup-competences
  setup-affordances
  setup-activityelements
  setup-studentelements
  setup-physicalenv
  reset-ticks
end

to setup-globals
  setup-valuelist
  set competence-list (list ["reading bus time tables" "driving license" "cycling proficiency"]  )
  set affordance-list (list ["bus" "road" "bus shelter" "rain gear" "car" "bike" "safety equipment" "bike storage"])
  set persontype-list (list ["Status" "Uninh" "CarefulSolo" "Prag" "Idealist"])
  set activity-list (list  ["Bike to lecture" green "bike"] ["Drive to lecture" blue "car side"] ["Take bus to lecture" yellow "bus" ] )
 ;;;; set activity-list2 (list "Bike to lecture" "Drive to lecture" "Take bus to lecture")
  set i 0
  set license-percentage 0.56
    ;; Status and CarefulSolo drivers have more chance to own a car
   set #Cars round( PercCar / 100 * NumStudents )

end

to setup-valuelist
  set value-list (list[ "Comfort" 2 3 1] ["Relaxation" 3 2 1] ["Efficiency"  2 3 1] ["Safety"  1 3 2] ["Flexibility"  2 3 1] ["Fun" 2 3 1 ] ["Environment"  3 1 2] )
end

to setup-values
  create-values 7
  set location 13
  ask values [
    set shape "star"
    set name item 0 item 0 value-list
    set ycor location
    set location location - 4.4
    set size 2
    set value-list but-first value-list]
  setup-valuelist
end

to setup-activities
  set i 0
  set location 12
  create-activities 3
  ask activities [
    set color item 1 item 0 activity-list
    set size 2
    set name item 0 item 0 activity-list
    set ycor location
    set location location - 9
    set xcor -10
    set shape item 2 item 0 activity-list
    set size 3
  ;;SETUP ACTIVITY VALUES -> done here instead of in the setup-elementrelation procedure, because here activities are called in the same order as they are given their other properties
    foreach value-list [
      [ part ] ->
      ask values [
          if name = item 0 part [ create-Act-strength-with myself [set value-strength item 1 part]
            set part remove-item 1 part
            set value-list replace-item i value-list part
            set i (i + 1)
            if i > 6 [ set i 0]
    ]]]
    set activity-list but-first activity-list]
  ;; The avarage opinion in the Netherlands about connection between value and activity; the stronger the connection, the brighter the color orange of the link
  ask Act-strengths [set color scale-color yellow value-strength 0 10 ]
    show-name
end


to setup-students
  set i 0
  create-students NumStudents
  set location 15
  ask students [ set shape "person student"
    set size 2
    set xcor 15
    if location < -15 [ set location 15]
    set ycor location
    ;; set begin color orange so that at the evaluation phase, the color is not confused with implementation of a certain acivity
    set color orange
    set location location - (32 / NumStudents)
    create-temporary-plot-pen (word who)
    set-plot-pen-color one-of base-colors
    set not-option []
    set TotalEnjoyment  []
    set TotalStress  []
    set name item i item 0 persontype-list
    set i i + 1
    if i > 4 [set i 0]
    check-ToM]
end

to check-ToM
  ;; setup ToM belonging to the prosocialness of someone, and the corresponding standard deviation (error) someone has when predicting others beliefs
  ;; agents never know éxactly the beliefs of another agent, even if their prosocialness is maximum (so sd always has a minimum level of 0.2)
  set ProSocial random-normal 0.48 0.42
  if prosocial > 1 [set prosocial 1]
  if prosocial < 0 [set prosocial 0]
  if random 100 > 50 [set overestimator true]
  ifelse prosocial > 0.8 [set ToM-deviation 0.3 set ExtraMean 0]
  [ifelse prosocial > 0.6 [set ToM-deviation 0.6 set ExtraMean 0.2] [
      ifelse prosocial > 0.4 [set ToM-deviation 0.9 set ExtraMean 0.4] [
        ifelse prosocial > 0.2 [set ToM-deviation 1.2 set ExtraMean 0.6] [
          set ToM-deviation 1.5 set ExtraMean 0.8]]]]
end


to SetFileName
  file-close
  ask students [
  let ws "ModelData"
  let xs name
  let ss ".csv"
  set FileName (word ws xs ss)
    Belief-Value_attribution ]
end


to Belief-Value_attribution
  file-open (FileName)
  let dataset csv:from-file FileName
  set personalval-list []
  foreach (csv:from-row file-read-line ";") [
    [x] -> set personalval-list lput (list(x)) personalval-list ]
   set personalvalues (csv:from-row file-read-line ";")
  set weights personalvalues
  set BIbeliefs (csv:from-row file-read-line ";")
  set Cbeliefs (csv:from-row file-read-line ";")
  set BUbeliefs (csv:from-row file-read-line ";")
  set traveltogether item 0 (csv:from-row file-read-line ";")
  combine
  file-close
end

to-report randomval [nmb]
  ifelse nmb = 3 [
    set nmb (random-float 3) + 7 ]
  [ ifelse nmb = 2 [
    set nmb (random-float 3) + 4  ]
  [set nmb random-float 4 ] ]
  report nmb
end

to combine
 set i 0
  ;; Create lists with values and how a student beliefs these are connected to personal-values and the different modes; personal-values, bike, car and bus.
 foreach personalval-list [
    [val] ->
  set val lput randomval (item 0 personalvalues) val
  set val lput randomval (item 0 BIbeliefs ) val
  set val lput randomval (item 0 Cbeliefs) val
  set val lput randomval (item 0 BUbeliefs) val
  set personalvalues but-first personalvalues
  set BIbeliefs but-first BIbeliefs
  set Cbeliefs but-first Cbeliefs
  set BUbeliefs but-first BUbeliefs
        set personalval-list replace-item i personalval-list val
    set i (i + 1)
    if i > 6 [ set i 0]]
end

to setup-competences
  set i 0
  create-competences 3
  ask competences [
    set name item i item 0 competence-list
    set i (i + 1)
    setxy random-xcor random-ycor]
end

to setup-affordances
  set i 0
  create-affordances 8
  ask affordances [
    set name item i item 0 affordance-list
    set i (i + 1)
    setxy random-xcor random-ycor ]
 show-name
end

to setup-activityelements
;;SETUP ACTIVITY COMPETENCES AND AFFORDANCES
;;DRIVING
  ask activities with [name = "Drive to lecture"] [
    create-has-competences-with competences with [name = "driving license"]
    create-has-affordances-with affordances with [name = "road" or name = "car"] ]
;;BUS
ask activities with [name = "Take bus to lecture"] [
    create-has-competences-with competences with [name ="reading bus time tables"]
    create-has-affordances-with affordances with [name = "bus" or name = "road" or name = "rain gear" or name = "bus shelter"] ]
;;BIKE
ask activities with [name = "Bike to lecture"] [
    create-has-competences-with competences with [name ="cycling proficiency"]
    create-has-affordances-with affordances with [name = "rain gear" or name = "bike" or name = "bike storage"] ]
end

to setup-studentelements
;;Setup relations between students and their elements
;;SETUP STUDENT VALUES
ask students[
foreach personalval-list[
      [ part ] ->
      ask values [
        if name = (item 0 part) [create-Stud-strength-with myself [set value-strength (item 1 part) ]
          ask Stud-strengths [set thickness value-strength / 50
            ;; only show the relatively stong links between values and students
            if value-strength < 4 [hide-link]
      set color scale-color lime value-strength 0 40 ]] ] ]
  ;;determine the total value strength a student has for all values
    set totalvaluestrength sum [value-strength] of  my-Stud-strengths
    ;;set new-valuestr the same as value-strengths, so the value of value-strength can be returned after the procedure of value sorting
    ask my-Stud-strengths [set new-valuestr value-strength]
  ;;setup the initial personal value-strengths in one list
  set specificvalues []
    set bikebeliefs []
    set carbeliefs []
    set busbeliefs []
    foreach personalval-list [
      [sub] -> set specificvalues lput item 1 sub specificvalues
  set bikebeliefs lput item 2 sub bikebeliefs
      set originalbikebeliefs bikebeliefs
      set carbeliefs lput item 3 sub carbeliefs
      set originalcarbeliefs carbeliefs
      set busbeliefs lput item 4 sub busbeliefs
      set originalbusbeliefs busbeliefs
  ]]


;;SETUP STUDENT AFFORDANCES
;;SETUP CAR OWNERS
  ;; Status and CarefulSolo drivers have more chance to own a car
  ifelse count (students with [name = "CarefulSolo" or name = "Status" or name = "Uninhibited"] ) > #Cars [
    ask n-of #Cars students with [name = "CarefulSolo" or name = "Status" or name = "Uninhibited"] [set car? true]]
  [ifelse count (students with [name != "Idealist"] ) > #Cars [
    ask n-of #Cars students with [name != "Idealist"] [set car? true]]
    [ask n-of #Cars students [set car? true]]]
  ask affordances with [name = "car" ] [create-has-affordances-with students with [car? = true]]
;;Setup all other affordances
 set bike-students ( ( PercBike / 100 ) * count students)
if bike-students < 1 [set bike-students 1 ]
ask affordances with [name = "bike"] [create-has-affordances-with n-of bike-students students]
ask affordances with [name = "rean gear"] [create-has-affordances-with  students]
ask affordances with [name = "safety equipment"] [create-has-affordances-with  students]
ask affordances with [name = "rain gear"] [create-has-affordances-with  students]

;;SETUP STUDENT COMPETENCES
  ;;SETUP DRIVERS LICENSE HOLDERS
  ask students with [car? = true] [set license? true]
  ;; how much above or below the average percentage of license holders are we now?
  let licenses (count students with [license? = true ]) / count students
  if ( ((license-percentage / 100) - licenses) * count (students with [car? != true] ) > 0 ) [ask n-of (((license-percentage / 100) - licenses) * count (students with [car? != true] )) students [set license? true] ]
  ask competences with [name = "driving license" ] [create-has-competences-with students with [license? = true]]
;  ask n-of

;;SETUP OTHER COMPETENCES
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DIT VERDER SPECIFICEREN; WAAROM DIT PERCENTAGE ETC.
  ;;Setup all other competences
ask competences with [name = "reading bus time tables"] [create-has-competences-with students]
ask competences with [name = "cycling proficiency"] [create-has-competences-with students]

end


to setup-physicalenv
  ;; We assume that every agent has the same access to the affordances bus, road, bus shelter and bike storage
  ask affordances with [name = "road" ] [
    create-has-affordances-with activities with [name = "Take bus to lecture" or name = "Drive to lecture" ]
  create-has-affordances-with students]
  ask affordances with [name = "bus shelter" ] [create-has-affordances-with activities with [name = "Take bus to lecture"]
  create-has-affordances-with students]
    ask affordances with [name = "bus" ] [create-has-affordances-with activities with [name = "Take bus to lecture"]
  create-has-affordances-with students]
    ask affordances with [name = "bike storage" ] [create-has-affordances-with activities with [name = "Bike to lecture"]
  create-has-affordances-with students]
  hide-competence
  hide-affordance

  ;; Now summarize which requirements an activity has in terms of elements and which belongings students have to offer to execute practices
ask students [
    set belongings [name] of link-neighbors]
  ask activities [
    set requirements [name] of link-neighbors]

  ;;What are no options for students to do individual due to a lack of affordances or competences?
   ask activities [
    ask students [
      foreach [requirements] of myself [
      [R ] ->
        if not member? R belongings [
          set not-option (lput [name] of myself not-option) ]] ] ]
end


to hide-competence
  if hide-competences [
  ask competences[
hide-turtle
      ask my-links [ hide-link ]] ]
end

to hide-affordance
    if hide-affordances [
  ask affordances[
hide-turtle
      ask my-links [ hide-link ]] ]
end


;;;;;;;;;;;;;;;;;;;;;;;;
;;;; MAIN PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  StoreOldBeliefs
  InventoryCarpoolers
  SortValues
  MatchAct
  Decide
  PersonalEvaluation
  SocialEvaluation
  travelsatisfaction
  UpdateBeliefs
  UpdateElementlist
  Plot_Beliefspace
  BeliefChange
  influencedstuds
  tick
end

to StoreOldBeliefs
  ask students [
      if ticks > 0
    [set PriviousBikeBel bikebeliefs
      set PriviousCarBel carbeliefs
      set PriviousBusBel busbeliefs ]

  ;;;Alsof make sure that SociallyInfluences is set back on false
   set SociallyInfluenced false]
  ;; And start recounting the number of students that is socially influenced in this specific tick
  set InfluencedStudents 0
end



to InventoryCarpoolers
  set numcarpoolers 0
  ask students [ if ticks > 0 [
    ;; partnerup means that someone is willing to travel together
    ifelse traveltogether = 3 [set partnerup true ] [
      ifelse traveltogether = 2 [ifelse  (random 100) > 50 [set partnerup true ] [set partnerup false]]
      [set partnerup false]]
   ask drivers [if partnerup = true and carpool? = true and member? "car" belongings  [set driveoption 1]] ] ]
end

to SortValues
  ask students [
   set new_totalval sum [new-valuestr] of  my-Stud-strengths
    ifelse (new_totalval >= 0 and any? my-Stud-strengths with [new-valuestr > 0.5] ) [
      ask one-of my-Stud-strengths with [ new-valuestr > 0.5 ] [
        ask myself [set target-value other-end]
        set new-valuestr (new-valuestr - 1)  ] ]
    [update-totalval]]
end

to update-totalval
  ask my-Stud-strengths [set new-valuestr value-strength]
set new_totalval totalvaluestrength
end


to MatchAct
  ;;firstly, the students that have a car decide whether or not they will use it, so others can anticipate on this fact
  foreach sort-on [( - driveoption)] students [
    [stud] -> ask stud [
    set chosen false
    set carsfull-impossible false
    foreach [personalval-list] of stud [
      [x] ->
      if item 0 x = [name] of target-value
        [ ask target-value
          [ask my-act-strengths [
           ifelse [name] of other-end = "Bike to lecture" [
              set preference item 2 x]
             [ifelse [name] of other-end = "Drive to lecture" [
            set preference item 3 x ] [
              set preference  item 4 x ]]]
            foreach sort-on [(- preference)] my-act-strengths [
              [str] ->
              ask myself [
               let otherdrivers count (other students with [driveoption = 1 and [name] of implement = "Drive to lecture"  and partnerup = true ] )
                set maxcarpoolers otherdrivers * 4
                ;; to get the option to carpool, one needs to have a peer that offers their car, but the decision-maker self also needs to be willing to travel together.
                if  (member? "Drive to lecture" not-option  and carpool? = true and otherdrivers > 0 ) [
                  ;; this variable helps detecting the right place where "drive to lecture" is located in the not-option list, so it can be removed
                set p 0
                    foreach not-option [
                    ;;; only when the not-option concerns driving, this is removed when carpooling becomes available
                    [NO] ->   ifelse NO = "Drive to lecture" [
                      set not-option remove-item p not-option
                      ;; the variable CarIsOption indicated that one can only travel by car because some one else offers to carpool
                    set CarIsOption true ]
                    ;; a variable that gives an indication on whether the "not-option" of driving was cancelled because carpooling became an option
                    [ set p p + 1 ]
              ]]]
             if not member? ([name] of [other-end] of str) [not-option] of myself [
                set candidate ([other-end] of str)
                ;; check if there is still room for you in one of the carpool-cars
                if [CarIsOption] of myself = true and [name] of candidate = "Drive to lecture" and numcarpoolers >= [maxcarpoolers] of myself [ask myself [set carsfull-impossible true ] ]
                ask myself [
                  if chosen = false and carsfull-impossible = false [set implement [candidate] of myself
                  if CarIsOption = true and [name] of implement = "Drive to lecture" [set numcarpoolers numcarpoolers + 1 ]]
                  set chosen true ]]]]]] ] ]
end

to Restore-notoption
  ;;this is only relevant for driving related not-options (as they can be removed from the restriction list when carpooling becomes available)
   ask activities [
    let focusactivity self
      foreach requirements [
      [R ] ->
      if not member? R [belongings] of myself and not member? ([name] of focusactivity) [not-option] of myself [
        ask myself [set not-option lput [name] of myself not-option ] ]]]
end


to Decide
  ;;If a student removes "Drive to lecture" from their not-option list because they could carpool, this should be restored for the next decision-round
  ask students [
  if not member? "Drive to lecture" not-option [restore-notoption ]
  set color [color] of implement
  if color = blue [set driving true]

 ; set bikers (other students with [color = green])
    set drivers ( other students with [color = blue]) ]
  ;  set publictransporters ( other students with [color = yellow]) ]
end

to PersonalEvaluation
  ask students [
    ;; determining which mode of transport is chosen and thus which value-satisfaction is relevant
    ifelse [name] of implement = "Bike to lecture" [
      set actnumber 0] [
      ifelse [name] of implement = "Drive to lecture" [
        set actnumber 1 ]
      [set actnumber 2]]

    ;; determining the enjoyment and stress in the previous round
     let PreviousEnjoy Enjoyment
     let PreviousStress Stress

     ;;determining the enjoyment experienced with the chosen transport mode
     let ComfortabilitySatisfaction item 0 weights * rank-enjoyment (item (2 + actnumber) item 0 personalval-list)
     let RelaxSatisfation item 1 weights * rank-enjoyment (item (2 + actnumber) item 1 personalval-list)
     let FunSatisfaction item 5 weights * rank-enjoyment (item (2 + actnumber) item 5 personalval-list)
     Set Enjoyment ((ComfortabilitySatisfaction + RelaxSatisfation + FunSatisfaction ) / 3)

    ;; determining the stress experiences with the chosen transport mode
      let FlexibilitySatisfaction item 4 weights * rank-stress (item (2 + actnumber) item 4 personalval-list)
      let EnvironmentSatisfaction item 6 weights * rank-stress (item (2 + actnumber) item 6 personalval-list)
      let SafetySatisfaction item 2 weights * rank-stress (item (2 + actnumber) item 2 personalval-list)
      let EfficiencySatisfaction item 3 weights * rank-stress (item (2 + actnumber) item 3 personalval-list)
      set Stress ((FlexibilitySatisfaction + EnvironmentSatisfaction + SafetySatisfaction + EfficiencySatisfaction) / 4)

    ;; variable needed for social comparison
    set StressEnjoyDifference Enjoyment - Stress

    ifelse Enjoyment - PreviousEnjoy >= 0 and Stress - PreviousStress <= 0 [set IntraPersSat (Sat + 0.5)]
    [ifelse (Enjoyment - PreviousEnjoy >= 0 and Stress - PreviousStress >= 0) or (Enjoyment - PreviousEnjoy <= 0 and Stress - PreviousStress <= 0) [set IntraPersSat Sat]
      [set IntraPersSat 0]]

  ]

end

to SocialEvaluation
ask students [
    set SocialDifferences []
    set like-minded []
    ;; determine the specificvalues one has again as these can change over time due to social interaction

    ask other students [
      ifelse [overestimator] of myself = true [
        set adjustedbeliefs map [t -> t + random-normal (Mean_deviation + [ExtraMean] of myself) [ToM-deviation] of myself] specificvalues]
      [set adjustedbeliefs map [t -> t - random-normal (Mean_deviation + [ExtraMean] of myself) [ToM-deviation] of myself] specificvalues]
      let difference (map - [specificvalues] of myself adjustedbeliefs)
      let difference2 (map abs difference)
      ;; the sum of all differences presents the overall differences
      let overalldifference (sum difference2)
      ;; make a list that combines the student id with the difference this agent and the asking agent have in values
      ask myself [
        set sdv 0
        set SocialDifferences lput list ([overalldifference] of myself ) ( [who] of myself ) SocialDifferences
      set SocialDifferences  sort-with [ l -> item 0 l ] SocialDifferences
    ;; ask if the student self is willing to travel together
    foreach socialdifferences [
      dif -> if item 0 dif <= Similarity_Threshold [
            ;; for more than half of their values, the agents cannot exceed the similarity boundary in order to consider themselves like-mindeds

            if not member? item 1 dif like-minded [
        let id item 1 dif
        ;; create list with id's of students you think are alike you
        set like-minded lput id like-minded ] ] ] ] ]
      ;; ask the students you have the least differences with (no more than 2 points) to travel together
        ;; update the relation with influencestrength; the more prosocial an agent is, the higher the update of inluence strength.
        ;; the affect on influence strength depends on one's own Pro-Socialness, but also the Pro-socialness of the other (when confronted with a noncooperative partner, prosocials will respond by reducing their own influencability).

    if like-minded != 0 [
;;;      set focusagent self
      ask other students [
        set focusagent myself
        if member? who [like-minded] of myself [
        ifelse any? my-relations with [ other-end = [focusagent] of myself ] [
          ask my-relations with [other-end = [focusagent] of myself] [
          ifelse [ProSocial] of myself > 0.7 [
            ifelse [ProSocial] of other-end > 0.7 [set influencestrength influencestrength + Influence] [if [ProSocial] of other-end > 0.4 [set influencestrength influencestrength + Influence / 2] ] ]
            [if [prosocial] of myself > 0.4 [ifelse [ProSocial] of other-end > 0.7 [set influencestrength influencestrength + Influence / 2 ] [if [ProSocial] of other-end > 0.4 [set influencestrength influencestrength + Influence / 4] ] ]] ] ]
      [ create-relation-with myself ] ] ] ]

      ;; move towards favourite travelpartner
      let xd 0.2
      if any? relation-neighbors [
        ask my-relations with-max [influencestrength] [
          ask myself [face [other-end] of myself ] ]
          fd xd ]

  ;; Compare your own stress and enjoyment to that of other agents you find important (i.e., are part of an agents 'like-minded' group)
    set AverageSocialDiff []
    let groupmember other students with [member? who [like-minded] of myself = true]
    let numgroupmembers count students with [member? who [like-minded] of myself = true]
    ifelse overestimator = true [
    foreach [StressEnjoyDifference] of groupmember [
        level ->  set averagesocialdiff lput (( StressEnjoyDifference - (level + random-normal (Mean_deviation + ExtraMean)  ToM-deviation )) / numgroupmembers )  averagesocialdiff ] ]
    [    foreach [StressEnjoyDifference] of groupmember [
      level ->  set averagesocialdiff lput (( StressEnjoyDifference - (level - random-normal (Mean_deviation + ExtraMean) ToM-deviation )) / numgroupmembers )  averagesocialdiff ] ]

    if not empty? averagesocialdiff [
      set SocialComp 0
      set averagesocialdiff mean averagesocialdiff
      ;; if the absolute difference between an agents travelsatisfaction and the average satisfaction of agents he consideres as like-minded is bigger than one, prosocials will consider this as disbalance for the group.
      if not (abs averagesocialdiff > 1) [ if ProSocial > 0.6 [ set SocialComp SocialComp + Sat ] ]
      ;; prosocials don't like to be top far removed from the group, whether it is that they score better or less good, they want to have a homogenous group
      if abs(averagesocialdiff) > 3  [ if ProSocial > 0.6 [ set SocialComp SocialComp - Sat] ]
      if averagesocialdiff > 3  [ if ProSocial < 0.6 [ set SocialComp SocialComp + Sat] ]
      if averagesocialdiff < 3  [ if ProSocial < 0.6 [ set SocialComp SocialComp - Sat ] ]
  ] ]

  ;;size of activities depends on the percentage of agents chosing them to implement.
  ask activities [set size 3 + 0.6 * size * ((count students with [color = [color] of myself]) / count students )]
end



to-report rank-stress [val]
  ifelse val > 7 [
    ; zero stress when the value is above 7
    set val 0 ] [
    ifelse val > 4 [
      ;; medium stress level
      set val 1 ] [
      ;; much stress experiences
      set val 2 ] ]
  report val
end

;; different reporting-process than the above (to-report rank-stress), as scale is in the opposite direction as the one for stress
to-report rank-enjoyment [val]
  ifelse val > 7 [
    ; highest level of enjoyment when value is above 7
    set val 2 ] [
    ifelse val > 4 [
      ;; medium enjoyment
      set val 1 ] [
      ;; no enjoyment of the chosen transport mode
      set val 0 ] ]
  report val
end

to-report sort-with [ key thelist ]
  report sort-by [ [a b] -> (runresult key a) < (runresult key b) ] thelist
end

to TravelSatisfaction
  ask students [
    Set Satisfaction (Enjoyment - Stress + IntraPersSat + SocialComp)
  ]
end


to UpdateBeliefs
  ;; SOCIAL ORIENTED UPDATE

  ask students [
;;;    set focusagent self
    set p 0
    ;; only relations which are still "active" (i.e., people still consider themselves as like-minded), are taken into account in the belief update section
    if like-minded != 0 [
     foreach like-minded [
        lm -> set targetagent other students with [who = lm]

        ask targetagent [
          if [name] of implement = "Bike to lecture" [
          ask myself [
              ifelse overestimator = true [
                set predictedbeliefs map [t -> t + random-normal (Mean_deviation + ExtraMean) ToM-deviation] [bikebeliefs] of myself ]
              [set predictedbeliefs map [t -> t - random-normal (Mean_deviation + ExtraMean) ToM-deviation] [bikebeliefs] of myself ]
          set BeliefDifference (map - bikebeliefs predictedbeliefs)
          set correspondingbeliefs bikebeliefs] ]

      if [name] of implement = "Drive to lecture" [
          ask myself [
              ifelse overestimator = true [
                set predictedbeliefs map [t -> t + random-normal (Mean_deviation + ExtraMean) ToM-deviation] [carbeliefs] of myself ]
              [set predictedbeliefs map [t -> t - random-normal (Mean_deviation + ExtraMean) ToM-deviation] [carbeliefs] of myself ]
          set BeliefDifference (map - carbeliefs predictedbeliefs)
          set correspondingbeliefs carbeliefs] ]

      if [name] of implement = "Take bus to lecture" [
          ask myself [
              ifelse overestimator = true [
                set predictedbeliefs map [t -> t + random-normal (Mean_deviation + ExtraMean)ToM-deviation] [busbeliefs] of myself]
              [set predictedbeliefs map [t -> t - random-normal (Mean_deviation + ExtraMean) ToM-deviation] [busbeliefs] of myself]
          set BeliefDifference (map - busbeliefs predictedbeliefs)
              set correspondingbeliefs busbeliefs] ]

ask myself [
          foreach BeliefDifference [
            subdiff ->
            ;; is there a significant difference left?
        if abs subdiff  >= 0.05 [
                set SociallyInfluenced true
                 ifelse item 0 [influencestrength] of my-relations with [member? other-end [targetagent] of myself] > 50 [ set beliefshift BeliefUpdate ]
                [ ifelse item 0 [influencestrength] of my-relations with [member? other-end [targetagent] of myself ] > 25 [ set beliefshift BeliefUpdate / 5 ]  [
                  set beliefshift BeliefUpdate / 10]]

     ;;     Determine direction of belief-update: ask if the difference is positive (and the other agent thus has a higher value for the belief in this relation)
              if subdiff > 0.05 [
                set  correspondingbeliefs replace-item p correspondingbeliefs ((item p correspondingbeliefs) - influencenumber)
              ask targetagent [ifelse [name] of implement = "Bike to lecture" [ask myself [set bikebeliefs correspondingbeliefs]] [
                ifelse [name] of implement = "Drive to lecture" [ ask myself [set carbeliefs correspondingbeliefs]]
                  [ask myself [set busbeliefs correspondingbeliefs]]] ]
              set  p p + 1
              if p = 6 [set p 0 ]]

                if subdiff < 0.05 [
                set  correspondingbeliefs replace-item p correspondingbeliefs ((item p correspondingbeliefs) + influencenumber)
              ask targetagent [ifelse [name] of implement = "Bike to lecture" [ask myself [set bikebeliefs correspondingbeliefs]] [
                ifelse [name] of implement = "Drive to lecture" [ ask myself [set carbeliefs correspondingbeliefs]]
                  [ask myself [set busbeliefs correspondingbeliefs]]] ]
              set  p p + 1
                if p = 6 [set p 0 ]] ]
  ]]]]]
    if SociallyInfluenced = true  [set InfluencedStudents InfluencedStudents + 1]]

    ;; PERSONAL ORIENTED UPDATE
  ask students [
    set iterate 0
    set iterate_val 0
          foreach value-list [
        val ->
      ifelse item 0 val = [name] of target-value [set iterate_val iterate] [
       set iterate iterate + 1]]

  ;; if -0.5 > satisfaction > 0.5, there is no personal oriented belief update, since the agent remains quite neutral about the decision.
  ;; if satisfaction was positive, the beliefrealtion between the targetvalue and implemented activity becomes bigger.
  ;; if satisfaction was negative, the beliefrealtion between the targetvalue and implemented activity becomes smaller.

  if [name] of implement = "Bike to lecture" [
      set iterate_act 2
    if satisfaction > 0.5 [set bikebeliefs replace-item iterate_val bikebeliefs (( item iterate_val bikebeliefs ) + 0.05 )]
        if satisfaction < 0.5 [set bikebeliefs replace-item iterate_val bikebeliefs (( item iterate_val bikebeliefs ) - 0.05 )]]

  if [name] of implement = "Drive to lecture" [
       set iterate_act 3
    if satisfaction > 0.5 [set carbeliefs replace-item iterate_val carbeliefs (( item iterate_val carbeliefs ) + 0.05 )]
            if satisfaction < 0.5 [set carbeliefs replace-item iterate_val carbeliefs (( item iterate_val carbeliefs ) - 0.05 )]]

  if [name] of implement = "Take bus to lecture" [
       set iterate_act 4
    if satisfaction > 0.5 [set busbeliefs replace-item iterate_val busbeliefs (( item iterate_val busbeliefs ) + 0.05 )]
      if satisfaction < 0.5 [set busbeliefs replace-item iterate_val busbeliefs (( item iterate_val busbeliefs ) - 0.05 )]]
  ]
end



to UpdateElementlist
  ask students [
        ;; The belief-scale is from 0 to 10, correct when these boundaries are exceeded
set p 0
   foreach bikebeliefs [
      bb -> if bb > 10 [set bb 10
      set bikebeliefs replace-item p bikebeliefs bb]
      if bb < 0 [set bb 0
      set bikebeliefs replace-item p bikebeliefs bb]
      set p p + 1
      if p > 6 [set p 0]]

    set p 0
   foreach carbeliefs [
      cb -> if cb > 10 [set cb 10
      set carbeliefs replace-item p carbeliefs cb]
      if cb < 0 [set cb 0
      set carbeliefs replace-item p carbeliefs cb]
      set p p + 1
      if p > 6 [set p 0]]

    set p 0
   foreach busbeliefs [
      bub -> if bub > 10 [set bub 10
      set busbeliefs replace-item p busbeliefs bub]
      if bub < 0 [set bub 0
      set busbeliefs replace-item p busbeliefs bub]
      set p p + 1
      if p > 6 [set p 0]]

    set p 0
    foreach personalval-list [
      subpart ->
      set subpart replace-item 2 subpart (item p bikebeliefs)
      set subpart replace-item 3 subpart (item p carbeliefs)
      set subpart replace-item 4 subpart (item p busbeliefs)
      set personalval-list replace-item p personalval-list subpart
      set p p + 1
      if p > 6 [set p 0]
  ] ]

end

to Plot_Beliefspace
  ask students [
    foreach personalval-list [
      pers ->
      if inspect_variable = item 0 pers [
  ifelse inspect_transportmode = "Bike" [
          set plot_belief item 2 pers ] [
        ifelse inspect_transportmode = "Car" [
          set plot_belief item 3 pers] [
            set plot_belief item 4 pers ] ] ] ]
    set-current-plot-pen (word who)
    plot plot_belief

    ;; To register the beliefs for specific value-activity combinations at the beginning of the simulation
  if ticks = 1 [
          foreach personalval-list [
      pers ->
      if inspect_variable = item 0 pers [
  ifelse inspect_transportmode = "Bike" [
          set InitialBeliefs item 2 pers ] [
        ifelse inspect_transportmode = "Car" [
          set InitialBeliefs item 3 pers] [
              set InitialBeliefs item 4 pers ] ] ] ] ]

          ;; To register the beliefs for specific value-activity combinations at the end of the simulation

        if ticks = 1500 [
          foreach personalval-list [
      pers ->
      if inspect_variable = item 0 pers [
  ifelse inspect_transportmode = "Bike" [
          set FinalBeliefs item 2 pers ] [
        ifelse inspect_transportmode = "Car" [
          set FinalBeliefs item 3 pers] [
            set FinalBeliefs item 4 pers ] ] ] ]
    ]]
end

to BeliefChange
  ask students [

    let EffectiveBikeBeliefShift (map - bikebeliefs originalbikebeliefs )
    let TotalBikeBeliefShift_aslist (map abs EffectiveBikeBeliefShift)

    let EffectiveCarBeliefShift (map - carbeliefs originalcarbeliefs )
    let TotalCarBeliefShift_aslist (map abs EffectiveCarBeliefShift)

    let EffectiveBusBeliefShift (map - busbeliefs originalbusbeliefs )
    let TotalBusBeliefShift_aslist (map abs EffectiveBusBeliefShift)

    set TotalBeliefChangeBike sum TotalBikeBeliefShift_aslist
    set TotalBeliefChangeCar sum TotalCarBeliefShift_aslist
    set TotalBeliefChangeBus sum TotalBusBeliefShift_aslist

    ;;Determine total shift in beliefs compared to starting point

    if ticks > 0 [
    set TickChangeBikeBel abs(sum bikebeliefs - sum PriviousBikeBel)
    set TickChangeCarBel abs(sum carbeliefs - sum PriviousCarBel)
    set TickChangeBusBel abs(sum busbeliefs - sum PriviousBusBel)
    set TotalTickChangeBel TickChangeBikeBel + TickChangeCarBel + TickChangeBusBel
    set TotalBeliefChange TotalBeliefChangeBike + TotalBeliefChangeCar + TotalBeliefChangeBus
    ]
  ]
    if ticks = 1500 [
    ask students [
    set finalbikebelief TotalBeliefChangeBike
    set finalcarbelief TotalBeliefChangeCar
    set finalbusbelief TotalBeliefChangeBus ]
  set meanbeliefshift mean [TotalBeliefChange] of students]
  set AllStudents_TotalTickChangeBel sum [TotalTickChangeBel] of students
  set mean_TotalTickChangeBel mean [TotalTickChangeBel] of students

  set carshare count students with [color = blue] / NumStudents
  set bikeshare count students with [color = green] / NumStudents
 set busshare count students with [color = yellow] / NumStudents
end

to influencedstuds
  set PercInfluenced InfluencedStudents / count students * 100

  ask students [
    set SocialGroup length like-minded + 1]
  set SocialGroupSA mean [SocialGroup] of students

  set zero count students with [plot_belief >= 0 and  plot_belief < 1]

  set one count students with [plot_belief >= 1 and plot_belief < 2]

  set two count students with [plot_belief >= 2 and plot_belief < 3]

  set three count students with [plot_belief >= 3 and plot_belief < 4]

  set four count students with [plot_belief >= 4 and plot_belief < 5]

  set five count students with [plot_belief >= 5 and plot_belief < 6]

  set six count students with [plot_belief >= 6 and plot_belief < 7]

  set seven count students with [plot_belief >= 7 and plot_belief < 8]

  set eight count students with [plot_belief >= 8 and plot_belief < 9]

  set nine count students with [plot_belief >= 9 and plot_belief < 10]



end


to show-name
  ask activities [
  ifelse show-names
    [set label name ]
    [set label ""]]
  ask values[
  ifelse show-names
    [set label name]
    [set label ""]]
  ask affordances [
  ifelse show-names
    [set label name]
    [set label ""]]
  ask competences [
  ifelse show-names
    [set label name]
    [set label ""]]
  ask students [
  ifelse show-names
    [set label name]
    [set label ""]]
end
@#$#@#$#@
GRAPHICS-WINDOW
152
10
693
552
-1
-1
16.152
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
1
1
1
ticks
30.0

BUTTON
8
13
74
46
NIL
setup\n
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
9
52
75
85
go once 
go\n
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
9
478
148
511
show-names
show-names
0
1
-1000

SWITCH
9
524
147
557
hide-competences
hide-competences
0
1
-1000

SWITCH
11
569
148
602
hide-affordances
hide-affordances
0
1
-1000

PLOT
700
10
1041
169
ModeChoices
decisions
mode-choice
0.0
8.0
0.0
5.0
true
false
"" ""
PENS
"Bike" 1.0 0 -13840069 true "" "plot count students with [color = green] "
"Car" 1.0 0 -13791810 true "" "plot count students with [color = blue] "
"Bus" 1.0 0 -1184463 true "" "plot count students with [color = yellow] "

BUTTON
9
91
75
124
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

MONITOR
693
315
767
360
Status
count students with [name = \"Status\"]
17
1
11

TEXTBOX
693
301
820
319
Types of students
11
0.0
1

MONITOR
694
363
767
408
Uninhibited
count students with [name = \"Uninh\"]
17
1
11

MONITOR
694
459
768
504
Pragmatic
count students with [name = \"Prag\"]
17
1
11

MONITOR
694
411
767
456
Careful Solo
count students with [name = \"CarefulSolo\" ]
17
1
11

MONITOR
694
509
769
554
Idealist
count students with [name = \"Idealist\" ]
17
1
11

SWITCH
9
437
148
470
Carpool?
Carpool?
0
1
-1000

PLOT
944
170
1104
339
#Students rejected to carpool
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
"default" 1.0 0 -16777216 true "" "plot count students with [carsfull-impossible = true]"

SLIDER
7
135
149
168
NumStudents
NumStudents
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
5
174
149
207
PercBike
PercBike
0
100
75.0
1
1
NIL
HORIZONTAL

PLOT
774
341
1104
553
Travel Satisfaction
NIL
NIL
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"Enjoyment" 1.0 0 -865067 true "" "plot [Enjoyment] of student 8"
"(-) Stress" 1.0 0 -526419 true "" "plot -1 * [Stress] of student 8"
"Intrapersonal Comp" 1.0 0 -4528153 true "" "plot [IntraPersSat] of student 8"
"Social Comp" 1.0 0 -408670 true "" "plot [SocialComp] of student 8"
"Travel Satisfaction" 1.0 0 -11085214 true "" "plot [satisfaction] of student 8"

PLOT
1048
11
1379
169
Change in beliefs (per tick)
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
"default" 1.0 0 -16777216 true "" "plot AllStudents_TotalTickChangeBel"

CHOOSER
7
214
145
259
Inspect_Variable
Inspect_Variable
"Comfort" "Relaxation" "Efficiency" "Safety" "Flexibility" "Fun" "Environment"
0

CHOOSER
10
263
144
308
Inspect_Transportmode
Inspect_Transportmode
"Bike" "Car" "Bus"
1

SLIDER
10
312
146
345
Similarity_Threshold
Similarity_Threshold
0
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
7
353
144
386
PercCar
PercCar
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
395
147
428
Mean_deviation
Mean_deviation
0
4
0.5
0.1
1
NIL
HORIZONTAL

PLOT
781
169
941
339
#Influenced Students
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
"default" 1.0 0 -16777216 true "" "plot InfluencedStudents"

PLOT
1107
171
1380
555
Belief Space
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

INPUTBOX
1439
254
1507
314
Influence
1.0
1
0
Number

TEXTBOX
1407
220
1557
248
Inputs used for sensitivity analysis
11
0.0
1

INPUTBOX
1440
318
1509
378
Sat
0.5
1
0
Number

INPUTBOX
1439
383
1509
443
BeliefUpdate
0.05
1
0
Number

MONITOR
176
557
287
602
Number of Cars
#Cars
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model shows a group of students forming a preference towards three different transport modes: the bus, car and bike. This preference rests on personal and social processes. Agents have values and personal beliefs that cause them to have personal preferences. Every preference they have, is subjected to personal evaluation. If the mode performs well in the context of that specific tick, beliefs on that mode being able to satisfy a certain value increase. If this is not the case, beliefs on that mode being able to satisfy the value can decrease. Besides this personal evaluation, agents can be socially influenced by other agents they find to be co-oriented. This similarity biased social influence causes agents to adapt their beliefs over time. The interaction between personal and social related belief adaption causes the opinion dynamics to best be described as polarising. 
This model in an extended version of another model. This model is extended with agents that have a theory of mind capacity. That means, that agents vary in their skills of correct conjectures on others' private characteristics. 

## HOW IT WORKS

Regarding the personal processes, through the rules of social practice theory agents first sense their own belongings and capacity. Through analysing what is possible for them, some transport modes will not be an option for the agent (e.g: an agent does not have a car). Through carpooling it might still be possible for an agent to choose the car, but not every agent is willing to take others with them and there are limited seats. Besides deciding on what the options are, agents form a preference through their personal values and beliefs. Every tick, an agent forms a preference towards a transport mode while keeping the satisfaction of one specific value in mind. Values are subjected to this satisfaction process more oftern if more importance is attained to them by the agent. While aiming to satisfy a value, the mode that is believed to have the strongest relation to this value and that is an option for the agent to implement, is prefered. 

After forming this preference, the prefered transport mode is subjected to personal and social evaluation. Personal evaluation determines if the chosen transport mode indeed satisfy the needs of the agents in terms of enjoyment, low stress experienced, higher or similar satisfaction as compared to previous choices and similar or higher satisfaction than co-oriented peers. Social evaluation lets agents compare their own beliefs to those of co-oriented peers in their reference group. Agents have the choice to adapt their beliefs on the chosen transport mode towards the beliefs of their co-oriented peers. A requirement for this belief adaption is that both the adapting and the agent there is adapted to are (moderately) prosocial. Agents adapt their beliefs towards what they think are the beliefs of co-oriented peers. The extent to which this is a correct interpretation of others' beliefs, depends on theory of mind capacity of the agent. 

After this evaluation process, the decision process starts from the start. 

## HOW TO USE IT

Choose the desired initial parameter settings and press setup. (Note that to the right of the interface there are three inputs of the sensitivity analysis that influence the simulation results when adjusted to different values. It is recommended to keep them to their initial values, unless the sensitivity of the model is analysed). 

Press Go. 
Agents start to move towards their co-oriented peers and form clutsters. 

Through selecting a value in the drop-down menue "Inspect_variable" and selecting a transport mode in the drop-down menue "Inspect_Transportmode", the plot "Belief Space" shows the beliefs of agents on the chosen value - transport mode relation. 


## THINGS TO NOTICE

The plot "Change in beliefs" shows the average points agents shift adapt beliefs with every tick. As can be seen, as the simulation progresses, this average amount of belief-points goes down. This is because agents might have reached one of the poles of the belief space, whereafter they cannot further increase or decrease their bliefs in this extreme direction. Another reason can be that they have adapted their beliefs towards the beliefs of their co-oriented peers and not do not have the incentives to further adapt their beliefs through social influence as they already have the same beliefs. 

Also note that many agents are restricted to choose the car, as only 10% owns a car when running with the initial parameter settings. Not every agents can carpool with another agents, as is shown in the "Rejected carpools" plot. When the amount of cars present in the model is increased using the slider "PercCar", more agents are able to choose the car. This is translated to a higher share of car users presented by the blue line in the plot "Mode Shares". 

Note that the "Belief Space" shows polarising behaviour. However, not all agents show polarising beliefs, as there are always some zealots. This is because some agents (can)not implement certain transport modes and therefore never evaluate these transport modes, or because some agents do not find this value important and therefore never choose a transport mode from the perspective of this value. 


## THINGS TO TRY
Play with different intial parameter settings in terms of percentage of agents owning a bike, a car, etc. and see what the effects are on belief dynamics. 


## EXTENDING THE MODEL
First of all, future research should focus on translating social characteristics of humans into ABM. This study contains limited social behaviour and relation dynamics. These limitations could not be resolved from previous research, resulting in a recommendation on further theoretical and applied research on how to give more depth to the social characteristics of agents. Especially the empirical research community within social sciences can help provide these missing puzzle pieces. 

The second recommendation for future work, is related to the inclusion of external effects and the broadening of options presented to agents. Because of the rather small scope of the models within in this study, many elements which could have far-reaching effects on opinion dynamics are not included. It is not stated that all these externalities and options should be included for a good model, but their impact on the system must be analysed in order to be able to leave them out without steering the results into a specific direction. 

Thirdly, the ease of belief adaption in this thesis should be subjected to further research. Expected is that beliefs connected to values found highly important by agents to not change with the same ease of beliefs connected to values with low importance. A certain level of opinion persistence should come in place. How this exactly would be translated into the model is recommended to analyse in further research. 


## RELATED MODELS
This model in an extended version of another model. This model is extended with agents that have a theory of mind capacity. That means, that agents vary in their skills of correct conjectures on others' private characteristics.  

## CREDITS AND REFERENCES
This model is made for obtaining a MSc. degree at the TU Delft, with help from my supervisors: Martijn Warnier, Caspar Chorus and Rijk Mercuur.
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

bike
false
1
Line -7500403 false 137 183 72 184
Circle -7500403 false false 65 184 22
Circle -7500403 false false 128 187 16
Circle -16777216 false false 177 148 95
Circle -16777216 false false 174 144 102
Circle -16777216 false false 24 144 102
Circle -16777216 false false 28 148 95
Polygon -2674135 true true 225 195 210 90 202 92 203 107 108 122 93 83 85 85 98 123 89 133 75 195 135 195 136 188 86 188 98 133 206 116 218 195
Polygon -2674135 true true 92 83 136 193 129 196 83 85
Polygon -2674135 true true 135 188 209 120 210 131 136 196
Line -7500403 false 141 173 130 219
Line -7500403 false 145 172 134 172
Line -7500403 false 134 219 123 219
Polygon -16777216 true false 113 92 102 92 92 97 83 100 69 93 69 84 84 82 99 83 116 85
Polygon -7500403 true false 229 86 202 93 199 85 226 81
Rectangle -16777216 true false 225 75 225 90
Polygon -16777216 true false 230 87 230 72 222 71 222 89
Circle -7500403 false false 125 184 22
Line -7500403 false 141 206 72 205

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

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

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

car side
false
0
Polygon -7500403 true true 19 147 11 125 16 105 63 105 99 79 155 79 180 105 243 111 266 129 253 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 101 87 73 108 171 108 151 87
Line -8630108 false 121 82 120 108
Polygon -1 true false 242 121 248 128 266 129 247 115
Rectangle -16777216 true false 12 131 28 143

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

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ToMGROUP" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1501"/>
    <metric>[name] of student 7</metric>
    <metric>[plot_belief] of student 7</metric>
    <metric>InfluencedStudents</metric>
    <metric>AllStudents_TotalTickChangeBel</metric>
    <metric>meanbeliefshift</metric>
    <enumeratedValueSet variable="hide-affordances">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercBike">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumStudents">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Similarity_Boundary">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Transportmode">
      <value value="&quot;Bike&quot;"/>
      <value value="&quot;Car&quot;"/>
      <value value="&quot;Bus&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Variable">
      <value value="&quot;Comfort&quot;"/>
      <value value="&quot;Relaxation&quot;"/>
      <value value="&quot;Efficiency&quot;"/>
      <value value="&quot;Safety&quot;"/>
      <value value="&quot;Flexibility&quot;"/>
      <value value="&quot;Fun&quot;"/>
      <value value="&quot;Environment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#Cars">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carpool?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-competences">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-names">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean-deviation">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ToMSimilarityBound" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1501"/>
    <metric>[name] of student 7</metric>
    <metric>[plot_belief] of student 7</metric>
    <metric>InfluencedStudents</metric>
    <metric>AllStudents_TotalTickChangeBel</metric>
    <metric>meanbeliefshift</metric>
    <enumeratedValueSet variable="hide-affordances">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercBike">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumStudents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Similarity_Boundary">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Transportmode">
      <value value="&quot;Bike&quot;"/>
      <value value="&quot;Car&quot;"/>
      <value value="&quot;Bus&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Variable">
      <value value="&quot;Comfort&quot;"/>
      <value value="&quot;Relaxation&quot;"/>
      <value value="&quot;Efficiency&quot;"/>
      <value value="&quot;Safety&quot;"/>
      <value value="&quot;Flexibility&quot;"/>
      <value value="&quot;Fun&quot;"/>
      <value value="&quot;Environment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#Cars">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carpool?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-competences">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-names">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean-deviation">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ModeShare" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1501"/>
    <metric>carshare</metric>
    <metric>bikeshare</metric>
    <metric>busshare</metric>
    <enumeratedValueSet variable="PercBike">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-affordances">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BeliefUpdate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Transportmode">
      <value value="&quot;Car&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Variable">
      <value value="&quot;Comfort&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_deviation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercCar">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumStudents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Similarity_Threshold">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-competences">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carpool?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-names">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100REFERENCE" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1501"/>
    <metric>[plot_belief] of student 7</metric>
    <metric>[name] of student 7</metric>
    <metric>PercInfluenced</metric>
    <metric>SocialGroupSA</metric>
    <metric>carshare</metric>
    <metric>bikeshare</metric>
    <metric>busshare</metric>
    <metric>mean_TotalTickChangeBel</metric>
    <metric>zero</metric>
    <metric>one</metric>
    <metric>two</metric>
    <metric>three</metric>
    <metric>four</metric>
    <metric>five</metric>
    <metric>six</metric>
    <metric>seven</metric>
    <metric>eight</metric>
    <metric>nine</metric>
    <enumeratedValueSet variable="hide-affordances">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercBike">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumStudents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Similarity_Threshold">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Transportmode">
      <value value="&quot;Bike&quot;"/>
      <value value="&quot;Car&quot;"/>
      <value value="&quot;Bus&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspect_Variable">
      <value value="&quot;Comfort&quot;"/>
      <value value="&quot;Relaxation&quot;"/>
      <value value="&quot;Efficiency&quot;"/>
      <value value="&quot;Safety&quot;"/>
      <value value="&quot;Flexibility&quot;"/>
      <value value="&quot;Fun&quot;"/>
      <value value="&quot;Environment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercCar">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carpool?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-competences">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-names">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_deviation">
      <value value="0.5"/>
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
