# A simple queue system

(def queue @{})

(defn subscribe
  "When QUEUE receives EVENT, apply F to the payload."
  [queue event f]
  (unless (get queue event)
    (put queue event @[]))
  (let [f-list (get queue event)]
    (array/push f-list f)))

(defn publish
  "Publish an EVENT with PAYLOAD to QUEUE."
  [queue event payload]
  #(pp "In publish")
  (let [f-list (or (get queue event) @[])]
    (map (fn [f] (f {:queue queue
                     :event event
                     :payload payload}))
         f-list)))

(defn publish-async
  "Publish an EVENT with PAYLOAD to QUEUE."
  [queue event payload]
  (let [f-list (or (get queue event) @[])]
    (map (fn [f] (:send (thread/new f)
                        {:queue queue
                         :event event
                         :payload payload}))
         f-list)))

(defn make-fn [f]
  (fn [{:queue queue
        :event event
        :payload payload}]
    (f payload)))

(defn make-fn-async [f]
  (fn [parent]
    (let [{:queue queue
           :event event
           :payload payload} (thread/receive math/inf)]
      (f payload))))
