(import ./test.deftest :as t)
(import ./io.fs)
(import ./util)
(import ./parse.core)

(defmacro is [a b]
  ~(t/deftest
    {:cost 0 :what "Expected results"}
    (t/eq ,a ,b)))

(defn test-fs []
  (is "lib//../lib/pubsub.janet"
      (io.fs/make-path "lib/pubsub.janet")))

(defn test-util []
  (is @{:a 3 :b 2}
      (util/zipmap [:a :b] [3 2]))
  (is @{:a 3 :b 2 :c 8}
      (util/zipmap [:a :b :c :d] [3 2 8]))
  )

(defn test-zone []
  (is @["H" "" "i"] (parse.core/split-line "H , i")))

(test-util)
(test-zone)


(t/run 10)
