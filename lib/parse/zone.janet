# Logic related to parsing map lines
(import ../pubsub :as q)
(import ../util :as u)

(import ./location)
(import ./entered-zone)
(import ./zone-label-to-key)

(length "")
# Parse a zone line
(defn split-line [s]
  (if (> 3 (length s))
    @[]
    (do
      (def type (string/slice s 0 1))
      (->> (string/split "," (string/slice s 1))
           (map string/trim)
           (array/concat @[type])))))

(assert (deep= @["L" "a" "b" "c"] (split-line "L a  ,b,c")))


(defn parse-line [s]
  (->> (split-line s)
       (u/zipmap [:t :x1 :y1 :z1 :x2 :y2 :z2 :r :g :b :a :label])))

(def assertion-result
  (parse-line
   "L 1186.0742, -2175.0840, 3.1260,  1215.0065, -2174.9312, 3.1260,  150, 0, 200"))

(assert (= (assertion-result :t) "L"))
(assert (= (assertion-result :x1) "1186.0742"))
(assert (= (assertion-result :y1) "-2175.0840"))
(assert (= (assertion-result :z1) "3.1260"))
(assert (= (assertion-result :x2) "1215.0065"))
(assert (= (assertion-result :y2) "-2174.9312"))
(assert (= (assertion-result :z2) "3.1260"))
(assert (= (assertion-result :r) "150"))
(assert (= (assertion-result :g) "0"))
(assert (= (assertion-result :b) "200"))
(assert (= (assertion-result :a) nil))
(assert (= (assertion-result :label) nil))

(defn load-zone [file]
  (->> (slurp file) (string/split "\n")))

(def points @{})

(var current-zone "ecommons")

(defn parse-current-zone-file []
  (let [file (string (u/file-finder "." "resources" 0 3) "/zones/" current-zone ".txt")]
    (if (get points file)
      (get points file)
      (put points file (->> (load-zone file) (map parse-line))))))

(defn get-points [name]
  (set current-zone name)
  (fn []
    (pp "The current zone is: ")
    (pp current-zone)
    (parse-current-zone-file)))

(var x 0)
(var y 0)

(defn load-log [file]
  (->> (slurp file) (string/split "\n")))

(defn log-line-handler [s]
  (cond
    (location/location? s)
    (q/publish q/queue ::player-loc (location/parse-log-line s))

    (entered-zone/entered-zone? s)
    (q/publish q/queue ::player-zone-change (entered-zone/entered-zone? s))

    :else (eprintf "Unrecognized line found: %s" s)))

(defn update-player-coords [{:x sx :y sy :z sz}]
  (pp "Updating player coords...")
  (pp sx)
  (pp sy)
  (set x (scan-number sx))
  (set y (scan-number sy)))

(defn update-player-zone [[zone-name]]
  (pp "NEW ZONE ENTERED...")
  (pp zone-name)
  (pp "Translated was: ")
  (pp (zone-label-to-key/label->key zone-name))
  (set current-zone (zone-label-to-key/label->key zone-name))
  )

(q/subscribe q/queue ::player-loc (q/make-fn update-player-coords))
(q/subscribe q/queue ::player-zone-change (q/make-fn update-player-zone))

#(log-line-handler sample-loc-line)

(defn parse-log-file [file]
  (->> (load-log file) (map log-line-handler)))


(defn get-player []
  (fn []
    # Need to ensure this runs in a different background thread
    # Ideally, we would parse log file and write zone/loc to sqlite
    # Then just select them out here.
    (parse-log-file "player.txt")
    #(pp "X is: ")
    #(pp x)
    @{:x x :y y}))

# (parse-map-lines "/home/mcarter/src/ahungry-map/res/maps/tutorialb.txt")
# Line format is as such:
# L 1186.0742, -2175.0840, 3.1260,  1215.0065, -2174.9312, 3.1260,  150, 0, 200
# L -12.7163, 162.0129, 0.0020,  12.6721, 162.0129, 0.0020,  0, 0, 0
# Hmm, note that label ones ignore the xyz2 so would be in slot :g
# P 624.6537, 2031.0975, 90.6260,  0, 0, 0,  3,  to_The_Estate_of_Unrest
# (defn parse-line [s]
#   (->>                          #(clojure.string/split s #",* +")
#    (u/zipmap [:t :x1 :y1 :z1 :x2 :y2 :z2 :r :g :b :a :label])))
