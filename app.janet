(import ./lib/parse.core :as zone)
(import ./lib/gui.core :as gui)

(defn main [_]
  (unless (> (length (dyn :args)) 1)
    (print (string "Usage: ./app.bin <path to logfile> <player name>"))
    (os/exit 1))
  (pp "Begin gui")
  (zone/set-player-name (get (dyn :args) 1))
  (zone/parse-current-zone-file)
  (zone/init-player (first (dyn :args )))
  (pp "done parse")
  (gui/main)
  # (gui/main
  #  (zone/get-points "ecommons")
  #  #(zone/get-points "./resources/zones/ecommons.txt")
  #  #(zone/get-points "./resources/zones/everfrost.txt")
  #  (zone/get-player))
  (pp "Hello"))
