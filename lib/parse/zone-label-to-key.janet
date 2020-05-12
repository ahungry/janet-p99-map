(import ../util :as u)

(def zones @{})

(defn zonelist-line->hash [line]
  (let [parts (string/split ";" line)]
    (put zones (get parts 0) (get parts 1))))

(defn load-zonelist []
  (->> (slurp (string (u/file-finder "." "resources" 0 3) "/zonelist.txt"))
       (string/split "\n")
       (map zonelist-line->hash)))

(defn label->key [label]
  (when (= 0 (length zones)) (load-zonelist))
  (get zones label))
