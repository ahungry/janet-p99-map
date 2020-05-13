(import ../util :as u)
(import ../io/fs)

(def zones @{})

(defn zonelist-line->hash [line]
  (let [parts (string/split ";" line)]
    (put zones (get parts 0) (get parts 1))))

(defn load-zonelist []
  (let [file (fs/make-path (string "resources/zonelist.txt"))]
    (->> (slurp file)
         (string/split "\n")
         (map zonelist-line->hash))))

(defn label->key [label]
  (when (= 0 (length zones)) (load-zonelist))
  (get zones label))
