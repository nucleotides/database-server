(ns nucleotides.database.metadata
  (:require
    [camel-snake-kebab.core           :as ksk]
    [clojure.java.jdbc                :as sql]
    [nucleotides.database.connection  :as con]))


(defn save-metadatum! [table-name entry]
  (let [query "INSERT INTO %1$s (name, description)
               SELECT '%2$s', '%3$s'
               WHERE NOT EXISTS (SELECT id FROM %1$s WHERE name = '%2$s')
               RETURNING id;"]
    (sql/query (con/create-connection)
               (format query
                       (str (ksk/->snake_case_string table-name) "_type")
                       (:name entry)
                       (:desc entry)))))
