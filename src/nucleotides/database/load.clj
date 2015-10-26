(ns nucleotides.database.load
  (:require
    [clojure.walk :as    walk]
    [clojure.set  :as    st]
            [nucleotides.database.connection :as con]
    [yesql.core   :refer [defqueries]]))

(defqueries "nucleotides/database/queries.sql")

(defn load-image-types
  "Select the image types and load into the database"
  [connection data]
  (for [entry data]
    (-> entry
        (select-keys ["image_type", "description"])
        (walk/keywordize-keys)
        (st/rename-keys {:image_type :name})
        (save-image-type<! {:connection connection}))))


(def initial-test-data
  {:images
   [{"image_type"      "type",
     "description"     "description"
     "image_instances" {"image" "image/name"
                        "tasks" ["default" "careful"]}}]})

;(load-image-types (con/create-connection) (:images initial-test-data))

(defn load-data
  "Load and update benchmark data in the database"
  [connection data]
  (load-image-types connection (:images data)))
