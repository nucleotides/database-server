(ns nucleotides.api.util
  (:require
    [nucleotides.database.connection :as con]))

(defn exists-fn [f]
  (fn [id]
    (-> {:id id}
        (f {:connection (con/create-connection)})
        (empty?)
        (not))))
