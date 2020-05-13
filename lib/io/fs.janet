# Handle disk operations easier

(defn file-finder
  "Given a file of NAME, travel up directories until it is found."
  [path name depth max-depth]
  (let [candidates (filter | (= $ name) (os/dir path))]
    (if (and (= 0 (length candidates))
             (< depth max-depth))
      (file-finder (string "../" path) name (inc depth) max-depth)
      (string (string/slice path 0 (- (length path) 1)) name))))

# (slurp
#  (string (file-finder "." "etc" 0 10) "/passwd"))

(defn get-separator []
  (if (= :windows (os/which)) "\\" "/"))

# We need to ensure this gets set once on initial first inclusion
# otherwise the dyn value will get altered as other things get loaded.
(def this-loc (dyn :source))

(defn get-directory [file]
  (pp "In dir: ")
  (pp file)
  (when file
    (if (= file "util.janet")
      "."
      (string/slice file 0 (- (length file) (length "/util.janet"))))))

(defn make-path
  "Create a path relative to project root."
  [path]
  (let [here (or (get-directory this-loc) (os/cwd))]
    (->>
     (string here "/../" path)
     (string/replace-all "/" (get-separator)))))

(pp (make-path "lib/pubsub.janet"))
