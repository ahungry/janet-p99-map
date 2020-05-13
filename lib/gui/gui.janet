(import ../parse/zone)

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
(var init-at 0)
(var set-timer? false)
(var safe-to-redraw? false)
(var drawn-once? false)

(defn safe-redraw
  "Attempt to avoid timing issues with redraw of canvas
during setup of the IupMainLoop by intentional stagger."
  []
  (when (or safe-to-redraw?
            (and (> init-at 0)
                 drawn-once?
                 (> (- (os/time) init-at) 1)))
    (do
      (unless safe-to-redraw?
        (set safe-to-redraw? true))
      (IupUpdate canvas))))

(defn add-timer []
  (def timer (IupTimer))
  (IupSetAttribute timer "TIME" "500")
  (iup-set-thunk-callback
   timer "ACTION_CB"
   (fn [_ _]
     (safe-redraw)))
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
     (safe-redraw)
     (const-IUP-DEFAULT)
     ))
  el)

(defn scale [n]
  (math/round (* n scale-factor)))

(defn s->n [s]
  (if (= nil s)
    0
    (scale (scan-number s))))

(defn point->line [ctx {:t t :x1 x1 :y1 y1 :x2 x2 :y2 y2}]
  (if (= "L" t)
    (-> ctx
        (set-attr "DRAWCOLOR" "100 100 100")
        (set-attr "DRAWSTYLE" "FILL")
        (IupDrawLine
         (+ x-offset (s->n x1))
         (+ y-offset (s->n y1))
         (+ x-offset (s->n x2))
         (+ y-offset (s->n y2))))
    #(pp t)
    ))

(defn zone->lines [ctx points]
  (map (partial point->line ctx) points))

(defn draw-player [ctx {:x x :y y}]
  (let [sx (+ x-offset (scale x))
        sy (+ y-offset (scale y))]
    (-> ctx
        (set-attr "DRAWCOLOR" "255 0 0")
        (set-attr "DRAWSTYLE" "FILL")
        (IupDrawArc
         sx
         sy
         (+ sx 15)
         (+ sy 15)
         360.0
         0.0))))

(defn make-canvas []
  (def ctx (IupCanvas "NULL"))
  (set canvas ctx)
  (iup-set-thunk-callback
   ctx "ACTION"
   (fn [ih _]
     (unless set-timer? (add-timer) (set set-timer? true))
     (IupDrawBegin ih)
     (set-attr ih "DRAWCOLOR" "240 240 250")
     (set-attr ih "DRAWSTYLE" "FILL")
     (IupDrawRectangle ih 0 0 2000 2000)

     # Ensure we show accurate/current map
     (def points (zone/parse-current-zone-file))
     (when points
       (zone->lines ih points))

     # Ensure we show player position
     (def player (zone/get-playerx))
     (when player
       (draw-player ih player))

     (IupDrawEnd ih)
     (set drawn-once? true)
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

(defn main []
  (iup-init)
  (def canvas (make-canvas))
  (show-dialog (make-dialog canvas))
  (set init-at (os/time))
  (IupMainLoop))
