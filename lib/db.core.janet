# Ensure we have a way to keep data persistent without worrying about
# shuffing it back and forth between threads.

(import ./io.fs :as fs)

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

(defn has-coords [name]
  (def res (with-db "SELECT COUNT(*) as c FROM player WHERE name = ?"
             [name]))
  (> (get (get res 0) :c) 0))

(defn insert-coords
  "Save coordinates."
  [name x y zone-name zone]
  (with-db "INSERT INTO player (name, x, y, at, zone_name, zone)
            VALUES (?, ?, ?, ?, ?, ?)" [name x y (os/time) zone-name zone]))
(defn update-coords
  "Save coordinates."
  [name x y zone-name zone]
  (with-db "UPDATE player SET
            x = ?
            , y = ?
            , at = ?
            , zone_name = ?
            , zone = ?
            WHERE name = ? " [x y (os/time) zone-name zone name]))

(defn set-coords [name x y zone-name zone]
  (if (has-coords name)
    (update-coords name x y zone-name zone)
    (insert-coords name x y zone-name zone)))

#(set-coords "Dummy" 1000 1000 "Everfrost" "everfrost")
#(get-coords "Dummy")
