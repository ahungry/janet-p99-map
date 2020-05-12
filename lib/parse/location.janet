# Match on entering a given location in log file
(import ../util :as u)

# [Fri Oct 25 13:41:22 2019] Your Location is 3435.10, 562.05, -27.64
(def peg-location
  '{:num (capture (some (+ :d "." "-")))
    :any (+ (range "09") (range "az") (range "AZ") ":" "-" " ")
    :main (* "[" (some :any) "] Your Location is " :num ", " :num ", " :num)})

(def sample-loc-line "[Fri Oct 25 13:41:22 2019] Your Location is 3435.10, 562.05, -27.64")

(assert
 (deep=
  @["3435.10" "562.05" "-27.64"]
  (peg/match
   peg-location sample-loc-line)))

(defn location? [s]
  (peg/match peg-location s))

(defn parse-log-line [s]
  (u/zipmap [:x :y :z] (peg/match peg-location s)))
