# Ensure we have a way to keep data persistent without worrying about
# shuffing it back and forth between threads.

(import ../io/fs)

(def db-name (fs/make-path "app.db"))

# This version may not support it, it doesn't seem to do anything useful...
# https://www.sqlite.org/wal.html
(defn create-db []
  (def db (sqlite3/open db-name))
  (sqlite3/eval db "PRAGMA journal_mode=WAL;")
  (sqlite3/eval db "create table player (name text, x text, y text, at date, zone text)")
  (sqlite3/close db))

(defn ensure-db []
  (or (os/stat db-name) (create-db)))

(defn set-coords
  "Save coordinates"
  [name x y zone]
  (try
    (do
      (ensure-db)
      (def db (sqlite3/open db-name))
      (sqlite3/eval db "INSERT INTO player (name, x, y, at, zone) VALUES (?, ?, ?, ?, ?)"
                    [name x y (os/time) zone])
      (sqlite3/close db))
    ([err]
     (set-coords name x y zone))))

(defn coord-res [res]
  (if (> (length res) 0)
    (let [[row] res]
      {:x (scan-number (get row :x))
       :y (scan-number (get row :y))
       :at (get row :at)
       :zone (get row :zone)})
    {:x 500 :y 500 :at 0 :zone "ecommons"}))

(defn get-coords
  "Pull out coordinates"
  [name]
  (try
    (do
      (ensure-db)
      (def db (sqlite3/open db-name))
      (def res (sqlite3/eval
                db
                "SELECT name, x, y, at, zone FROM
 player WHERE name = ? ORDER BY at DESC LIMIT 1"
                [name]))
      (sqlite3/close db)
      (coord-res res))
    ([err]
     (get-coords name))))

# (set-coords "Dummy" 1000 1000 "everfrost")
# (get-coords "Dummy")
