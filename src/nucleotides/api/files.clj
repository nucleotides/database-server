(ns nucleotides.api.files
  (:require [yesql.core          :refer [defqueries]]
            [clojure.string                  :as st]
            [nucleotides.database.connection :as con]))

(defqueries "nucleotides/api/files.sql")

(defn invalid-files
  "Returns a list of invalid file types"
  [xs]
  (let [to-str  #(st/replace (str %) ":" "")
        allowed (->> {:connection (con/create-connection)}
                     (all-file-types {})
                     (map :name)
                     (into #{}))]
    (clojure.set/difference (set (map to-str xs)) allowed)))
