(import ../lib/test/deftest :as t)
(import ../lib/util)
(import ../lib/parse/zone)

(defmacro is [a b]
  ~(t/deftest
    {:cost 0 :what "Expected results"}
    (t/eq ,a ,b)))

(defn test-util []
  (is @{:a 3 :b 2} (util/zipmap [:a :b] [3 2]))
  (is @{:a 3 :b 2 :c 8} (util/zipmap [:a :b :c :d] [3 2 8]))
  )

(defn test-zone []
  (is @["H" "" "i"] (zone/split-line "H , i")))

(test-util)
(test-zone)

(t/run 10)
