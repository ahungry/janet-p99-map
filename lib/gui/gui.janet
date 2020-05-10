(defn set-attr [x k v]
  (IupSetAttribute x k v)
  x)

(defn get-points []
  [
   {:x1 0 :y1 0 :x2 100 :y2 0}
   {:x1 100 :y1 0 :x2 100 :y2 100}
   ])

(def scale-factor 0.1)


(defn scale [n]
  (* n scale-factor))

(defn s->n [s]
  (if (= nil s)
    0
    (math/round (scale (scan-number s)))))

(defn point->line [ctx {:x1 x1 :y1 y1 :x2 x2 :y2 y2}]
  (-> ctx
      (set-attr "DRAWCOLOR" "0 255 255")
      (set-attr "DRAWSTYLE" "FILL")
      (IupDrawLine
       (+ 300 (s->n x1))
       (+ 300 (s->n y1))
       (+ 300 (s->n x2))
       (+ 300 (s->n y2)))))

(defn zone->lines [ctx points]
  (map (partial point->line ctx) points))

(defn make-canvas [f-get-points]
  (def canvas (IupCanvas "NULL"))
  (iup-set-thunk-callback
   canvas "ACTION"
   (fn [_ _]
     (IupDrawBegin canvas)
     (set-attr canvas "DRAWCOLOR" "0 0 0")
     (set-attr canvas "DRAWSTYLE" "FILL")
     (IupDrawRectangle canvas 0 0 100 100)
     (zone->lines canvas (f-get-points))
     (IupDrawEnd canvas)
     (const-IUP-DEFAULT)))
  canvas)

(defn make-dialog [children]
  (-> (IupDialog (or children "NULL"))
      (set-attr "TITLE" "p99 mapper")
      (set-attr "SIZE" "600x300")))

(defn show-dialog [dialog]
  (IupShowXY dialog (const-IUP-CENTER) (const-IUP-CENTER)))

(defn iup-init []
  (IupOpen (int-ptr) (char-ptr)))

(defn main [f-get-points]
  (iup-init)
  (show-dialog
   (make-dialog
    (make-canvas f-get-points)))
  (IupMainLoop))
