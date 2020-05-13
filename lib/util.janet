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
