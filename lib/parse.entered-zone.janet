# Match on entering a zone in log file
(import ./util :as u)

# [Fri Oct 25 13:40:49 2019] You have entered Everfrost.
(def peg-entered-zone
  '{:any (+ (range "09") (range "az") (range "AZ") ":" "-" " ")
    :main (* "[" (some :any) "] You have entered " (capture (some (+ :w :s))) ".")})

(def sample-entered-zone-line "[Fri Oct 25 13:40:49 2019] You have entered Everfrost.")

(assert
 (deep=
  @["Everfrost"]
  (peg/match
   peg-entered-zone sample-entered-zone-line)))

(defn entered-zone? [s]
  (peg/match peg-entered-zone s))
