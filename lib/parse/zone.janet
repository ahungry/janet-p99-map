# Logic related to parsing map lines
(import ../pubsub :as q)
(import ../util :as u)
(import ../io/fs :as fs)
(import ../db/persist :as p)

(import ./location)
(import ./entered-zone)
(import ./zone-label-to-key)

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

(var current-zone "ecommons")
(var current-zone-name "East Commonlands")
(var current-zone-points @[])

# Treating an in-memory points array as a reference
# for the draw fn causes segfaults - maybe marshal is too large?
(defn parse-current-zone-file []
  (def maybe-points (p/get-zone current-zone))

  (if (and maybe-points (> (length maybe-points) 0))
    maybe-points
    (let [file (fs/make-path (string "resources/zones/" current-zone ".txt"))]
      (eprintf "Loading zone for the first time, please wait...")
      (def zone-points (->> (load-zone file) (map parse-line)))
      (map (fn [xs]
             (pp xs)
             (p/set-zone current-zone xs))
           zone-points)
      zone-points)))

(defn get-points []
  (if (and current-zone-points
           (> (length current-zone-points) 0))
    current-zone-points
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

    :else nil
    #:else (eprintf "Unrecognized line found: [%s]" s)
    )
  )

(defn update-player-coords [{:x sx :y sy :z sz}]
  # (pp "Updating player coords...")
  # (pp sx)
  # (pp sy)
  (set x (scan-number sx))
  (set y (scan-number sy))
  (p/set-coords "Dummy" x y current-zone-name current-zone))

(defn update-player-zone [[zone-name]]
  (pp "NEW ZONE ENTERED...")
  (pp zone-name)
  (pp "Translated was: ")
  (pp (zone-label-to-key/label->key zone-name))
  (set current-zone-name zone-name)
  (set current-zone (zone-label-to-key/label->key zone-name))
  (p/set-coords "Dummy" x y current-zone-name current-zone))

(q/subscribe q/queue ::player-loc (q/make-fn update-player-coords))
(q/subscribe q/queue ::player-zone-change (q/make-fn update-player-zone))

#(log-line-handler sample-loc-line)

(var fh nil)
(var fh-last-size 0)

(defn parse-log-file-slow
  "Parse/handle every possible line in the file."
  [file]
  (pp "Doing initial slow read...")
  (->> (load-log file) (map log-line-handler)))

(defn parse-log-file
  "Just work on new lines that get added after initial parse."
  [file]
  (if (= nil fh)
    (do
      (parse-log-file-slow file)
      (let [{:size size} (os/stat file)]
        (set fh (file/open file :r))
        # Put the cursor at the end of the file
        (set fh-last-size size)
        (file/seek fh :cur (- size 0))))
    # Here we know we have the fh and we're at the end of it.
    (when (> (get (os/stat file) :size) fh-last-size)
      (pp "File grew in size, reading from it now...")
      (set fh-last-size (get (os/stat file) :size))
      (def lines (file/read fh :all))
      (pp "And we see these lines: ")
      (pp lines)
      (map log-line-handler (string/split "\n" lines)))))

(defn init-player [log-file]
  (thread/new
   (fn [parent]
     (while true
       (do
         (os/sleep 0.3)
         (parse-log-file log-file))))))

(defn get-player []
  (fn []
    # Need to ensure this runs in a different background thread
    # Ideally, we would parse log file and write zone/loc to sqlite
    # Then just select them out here.

    #(parse-log-file "player.txt")
    #(pp "X is: ")
    #(pp x)
    (def m (p/get-coords "Dummy"))
    (unless (= current-zone (get m :zone))
      (set current-zone-name (get m :zone-name))
      (set current-zone (get m :zone)))
    m))

(defn get-playerx []
  (def m (p/get-coords "Dummy"))
  (unless (= current-zone (get m :zone))
    (set current-zone-name (get m :zone-name))
    (set current-zone (get m :zone)))
  m)

# (parse-map-lines "/home/mcarter/src/ahungry-map/res/maps/tutorialb.txt")
# Line format is as such:
# L 1186.0742, -2175.0840, 3.1260,  1215.0065, -2174.9312, 3.1260,  150, 0, 200
# L -12.7163, 162.0129, 0.0020,  12.6721, 162.0129, 0.0020,  0, 0, 0
# Hmm, note that label ones ignore the xyz2 so would be in slot :g
# P 624.6537, 2031.0975, 90.6260,  0, 0, 0,  3,  to_The_Estate_of_Unrest
# (defn parse-line [s]
#   (->>                          #(clojure.string/split s #",* +")
#    (u/zipmap [:t :x1 :y1 :z1 :x2 :y2 :z2 :r :g :b :a :label])))
