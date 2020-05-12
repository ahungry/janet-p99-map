(defn zipmap [ks vs]
  (if (or (= nil ks)
          (= nil vs))
    {}
    (do
      (def res @{})
      (map (fn [k v]
             (put res k v)) ks vs)
      res)))

(assert (deep= @{:x 1 :y 2} (zipmap [:x :y] [1 2])))

(defn file-finder
  "Given a file of NAME, travel up directories until it is found."
  [path name depth max-depth]
  (let [candidates (filter | (= $ name) (os/dir path))]
    (if (and (= 0 (length candidates))
             (< depth max-depth))
      (file-finder (string "../" path) name (inc depth) max-depth)
      (string (string/slice path 0 (- (length path) 1)) name))))

(slurp
 (string (file-finder "." "etc" 0 10) "/passwd"))
