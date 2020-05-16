(defmacro make-proxy-fn-around
  "Wrap function F with function G."
  [f g]
  ~(def ,f (fn proxied [& args]
             (,g ,f ;args))))

# Force all future import calls to use the :fresh true setting
(make-proxy-fn-around
 import* (fn [f & xs]
           (f ;xs :fresh true)
           ))
