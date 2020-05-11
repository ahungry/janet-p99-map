(def KEY_UP 65362)
(def KEY_DOWN 65364)
(def KEY_LEFT 65361)
(def KEY_RIGHT 65363)
(def KEY_O 111)
(def KEY_I 105)
(def KEY_J 106)
(def KEY_K 107)
(def KEY_H 104)
(def KEY_L 108)

(defn set-attr [x k v]
  (IupSetAttribute x k v)
  x)

(defn get-points []
  [
   {:x1 0 :y1 0 :x2 100 :y2 0}
   {:x1 100 :y1 0 :x2 100 :y2 100}
   ])

(var canvas nil)
(var set-timer? false)

(defn add-timer []
  (def timer (IupTimer))
  (IupSetAttribute timer "TIME" "100")
  (iup-set-thunk-callback
   timer "ACTION_CB"
   (fn [_ _]
     (IupRedraw canvas 0)))
  (IupSetAttribute timer "RUN" "yes")
  canvas)

(var scale-factor 0.1)
(var x-offset 300)
(var y-offset 300)

(defn key-left []
  (set x-offset (+ x-offset 50) ))

(defn key-right []
  (set x-offset (- x-offset 50) ))

(defn key-up []
  (set y-offset (+ y-offset 50) ))

(defn key-down []
  (set y-offset (- y-offset 50) ))

(defn key-zoom-in []
  (set scale-factor (* 1.2 scale-factor)))

(defn key-zoom-out []
  (set scale-factor (* 0.8 scale-factor)))

(defn key-handler [k]
  (case k
    536870984 (pp "Show help here")
    #536870991 (file-selector nil nil)
    KEY_UP    (key-up)
    KEY_K     (key-up)
    KEY_DOWN  (key-down)
    KEY_J     (key-down)
    KEY_LEFT  (key-left)
    KEY_H     (key-left)
    KEY_RIGHT (key-right)
    KEY_L     (key-right)
    KEY_I     (key-zoom-in)
    KEY_O     (key-zoom-out)
    (do (print (string/format "Unhandled key value: [%d]\n" k)))))

# Do additional mapping work in iupkey.h
(defn bind-keys [el]
  (iup-set-thunk-callback
   el "K_ANY"
   (fn [ih k]
     (pp "Working on K_ANY")
     (unless set-timer? (add-timer) (set set-timer? true))
     (key-handler k)
     (const-IUP-DEFAULT)
     ))
  el)

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
       (+ x-offset (s->n x1))
       (+ y-offset (s->n y1))
       (+ x-offset (s->n x2))
       (+ y-offset (s->n y2)))))

(defn zone->lines [ctx points]
  (map (partial point->line ctx) points))

(defn make-canvas [f-get-points]
  (def ctx (IupCanvas "NULL"))
  (set canvas ctx)
  (iup-set-thunk-callback
   ctx "ACTION"
   (fn [_ _]
     (unless set-timer? (add-timer) (set set-timer? true))
     (IupDrawBegin ctx)
     (set-attr ctx "DRAWCOLOR" "0 0 0")
     (set-attr ctx "DRAWSTYLE" "FILL")
     (IupDrawRectangle ctx 0 0 100 100)
     (when (f-get-points)
       (zone->lines ctx (f-get-points)))
     (IupDrawEnd ctx)
     (const-IUP-DEFAULT)))
  ctx)

(defn make-dialog [children]
  (def vbox (IupVbox (or children "NULL") (int-ptr)))
  (bind-keys vbox)
  (-> (IupDialog vbox)
      (set-attr "TITLE" "p99 mapper")
      (set-attr "SIZE" "600x300")
      #bind-keys
      ))

(defn show-dialog [dialog]
  (IupShowXY dialog (const-IUP-CENTER) (const-IUP-CENTER)))

(defn iup-init []
  (IupOpen (int-ptr) (char-ptr)))

(defn main [f-get-points]
  (iup-init)
  (def canvas (make-canvas f-get-points))
  (show-dialog (make-dialog canvas))
  (IupMainLoop))
