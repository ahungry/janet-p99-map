# Logic related to parsing map lines

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

(defn zipmap [ks vs]
  (def res @{})
  (map (fn [k v]
         (put res k v)) ks vs)
  res)

(assert (deep= @{:x 1 :y 2} (zipmap [:x :y] [1 2])))


(defn parse-line [s]
  (->> (split-line s)
       (zipmap [:t :x1 :y1 :z1 :x2 :y2 :z2 :r :g :b :a :label])))

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

(defn parse-zone-file [file]
  (if (get points file)
    (get points file)
    (put points file (->> (load-zone file) (map parse-line)))))

(defn get-points [file]
  (fn []
    (parse-zone-file file)))

# (parse-map-lines "/home/mcarter/src/ahungry-map/res/maps/tutorialb.txt")
# Line format is as such:
# L 1186.0742, -2175.0840, 3.1260,  1215.0065, -2174.9312, 3.1260,  150, 0, 200
# L -12.7163, 162.0129, 0.0020,  12.6721, 162.0129, 0.0020,  0, 0, 0
# Hmm, note that label ones ignore the xyz2 so would be in slot :g
# P 624.6537, 2031.0975, 90.6260,  0, 0, 0,  3,  to_The_Estate_of_Unrest
# (defn parse-line [s]
#   (->>                          #(clojure.string/split s #",* +")
#    (zipmap [:t :x1 :y1 :z1 :x2 :y2 :z2 :r :g :b :a :label])))
