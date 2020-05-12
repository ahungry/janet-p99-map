(import lib/parse/zone :as zone)
(import lib/gui/gui :as gui)

(defn main [_]
  (pp "Begin gui")
  (gui/main
   (zone/get-points "ecommons")
   #(zone/get-points "./resources/zones/ecommons.txt")
   #(zone/get-points "./resources/zones/everfrost.txt")
   (zone/get-player))
  (pp "Hello"))
