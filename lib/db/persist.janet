(def cur-file (dyn :source))

(pp cur-file)

(module/find "test.txt")

(pp (os/cwd))
