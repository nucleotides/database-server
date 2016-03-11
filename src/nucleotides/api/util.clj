(ns nucleotides.api.util
  (:require
    [nucleotides.database.connection :as con]))

(defn is-valid-integer-id? [id]
  (->> (str id)
       (re-find (re-pattern "^\\d+$"))
       (nil?)
       (not)))

(defn exists-fn [f]
  (fn [id]
    (-> {:id id}
        (f {:connection (con/create-connection)})
        (empty?)
        (not))))

(defn integer-id-exists-fn? [f]
  (fn [id]
    (every?
      #(true? (% id))
      [is-valid-integer-id? (exists-fn f)])))
