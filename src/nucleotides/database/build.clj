(ns nucleotides.database.build
  (:gen-class)
  (:require
    [clojure.java.jdbc :as sql]
    [nucleotides.util  :as util]
    [migratus.core     :as mg]))

(def variable-names
  {:user      "POSTGRES_USER"
   :password  "POSTGRES_PASSWORD"
   :url       "POSTGRES_HOST"})

(defn create-db-spec [vars]
  {:classname    "org.postgresql.Driver"
   :subprotocol  "postgresql"
   :subname      (:url vars)
   :user         (:user vars)
   :password     (:password vars)})

(defn -main [& args]
  (let [vars    (util/fetch-variables! variable-names)
        db-spec (create-db-spec vars)]
    (mg/migrate db-spec)))
