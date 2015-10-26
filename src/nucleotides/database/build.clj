(ns nucleotides.database.build
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

(defn migrate [connection initial-data]
  (do
    (mg/migrate (create-migratus-spec connection))
    (loader/load-data connection initial-data)))

(defn load-data-files [directory]
  (let [file-names [:image :data_type]
        f          (fn [file]
                     (->> (str (name file) ".yml")
                          (io/file directory)
                          (slurp)
                          (yaml/parse-string)))]
        (zipmap file-names (map f file-names))))

(defn -main [& args]
  (let [data (load-data-files (first args))]
    (do
      (migrate (con/create-connection) data)
      (System/exit 0))))
