# Ensure we have a way to keep data persistent without worrying about
# shuffing it back and forth between threads.

(import ../io/fs)

(def db-name (fs/make-path "app.db"))

# This version may not support it, it doesn't seem to do anything useful...
# https://www.sqlite.org/wal.html
(defn create-db []
  (def db (sqlite3/open db-name))
  (sqlite3/eval db "PRAGMA journal_mode=WAL;")
  (sqlite3/eval db "create table player (
          name text,
          x text,
          y text,
          at date,
          zone_name text,
          zone text)")
  (sqlite3/eval db "create table zone (
          name text,
          t text,
          x1 text,
          y1 text,
          z1 text,
          x2 text,
          y2 text,
          z2 text,
          r text,
          g text,
          b text,
          a text,
          label text
          )")
  (sqlite3/close db))

(defn ensure-db []
  (or (os/stat db-name) (create-db)))

(defn with-db [sql args]
  (try
    (do
      (ensure-db)
      (def db (sqlite3/open db-name))
      (def res (sqlite3/eval db sql args))
      (sqlite3/close db)
      res)
    ([err]
     (pp "With-db encountered error: ")
     (pp err)
     (os/sleep 0.05)
     (with-db sql args))))

(defn set-coords
  "Save coordinates."
  [name x y zone-name zone]
  (with-db "INSERT INTO player (name, x, y, at, zone_name, zone)
            VALUES (?, ?, ?, ?, ?, ?)" [name x y (os/time) zone-name zone]))

(defn set-zone
  "Save a previously parsed zone file."
  [name {:t t :x1 x1 :y1 y1 :z1 z1 :x2 x2 :y2 y2 :z2 z2 :r r :g g :b b :a a :label label}]
  (with-db "INSERT INTO zone (name, t, x1, y1, z1, x2, y2, z2, r, g, b, a, label)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    [name t x1 y1 z1 x2 y2 z2 r g b a label]))

(defn coord-res [res]
  (if (> (length res) 0)
    (let [[row] res]
      {:x (scan-number (get row :x))
       :y (scan-number (get row :y))
       :at (get row :at)
       :zone-name (get row :zone_name)
       :zone (get row :zone)})
    {:x 500 :y 500 :at 0 :zone-name "East Commonlands" :zone "ecommons"}))

(defn get-coords
  "Pull out coordinates."
  [name]
  (-> (with-db "SELECT name, x, y, at, zone_name, zone
            FROM player WHERE name = ?
            ORDER BY at DESC LIMIT 1" [name])
      coord-res))

(defn cast-zone [m] m)

(defn get-zone
  "Pull out all previously parsed zone entries."
  [name]
  (-> (with-db "SELECT name, t, x1, y1, z1, x2, y2, z2, r, g, b, a, label
                FROM zone WHERE name = ?" [name])
      cast-zone))

#(set-coords "Dummy" 1000 1000 "Everfrost" "everfrost")
#(get-coords "Dummy")
