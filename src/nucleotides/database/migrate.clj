(ns nucleotides.database.migrate
  (:gen-class)
  (:require
    [clojure.java.io                 :as io]
    [migratus.core                   :as mg]
    [clj-yaml.core                   :as yaml]
    [nucleotides.util                :as util]
    [nucleotides.database.load       :as loader]
    [nucleotides.database.connection :as con]))

(defn create-migratus-spec [sql-params]
  {:store                :database
   :migration-dir        "migrations/"
   :migration-table-name "db_version"
   :db                   sql-params})

(defn load-data-file [directory file]
  (->> (str (name file) ".yml")
       (io/file directory)
       (slurp)
       (yaml/parse-string)))

(defn load-data-files [directory]
  (let [file-names [:image :data :benchmark_type]]
    (zipmap file-names (map (partial load-data-file directory) file-names))))

(defn migrate [directory]
  (let [data (load-data-files directory)
        con  (con/create-connection)]
    (mg/migrate (create-migratus-spec con))
    (loader/load-data con data)))

(defn -main [& args]
  (migrate (first args))
  (System/exit 0))
