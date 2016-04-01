(ns nucleotides.database.migrate
  (:gen-class)
  (:require
    [clojure.java.io                 :as io]
    [clojure.string                  :as st]
    [migratus.core                   :as mg]
    [clj-yaml.core                   :as yaml]
    [camel-snake-kebab.core          :as ksb]
    [nucleotides.util                :as util]
    [nucleotides.database.load       :as loader]
    [nucleotides.database.connection :as con]))

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn load-data-files [directory]
  (merge
    (load-yml-files-from directory)
    (load-yml-files-from (str directory "/type"))
    (load-yml-files-from (str directory "/input_data"))))

(defn migrate [directory]
  (let [data (load-data-files directory)
        con  (con/create-connection)]
    (mg/migrate (create-migratus-spec con))
    (loader/load-data con data)))

(defn -main [& args]
  (migrate (first args))
  (System/exit 0))
