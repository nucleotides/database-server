(ns event-api.core
  (:gen-class)
  (:require
    [nucleotides.util :as util]
    [migratus.core    :as mg]))

(def variable-names
  {:user      "MYSQL_USER"
   :password  "MYSQL_PASSWORD"
   :url       "MYSQL_HOST"})

(defn config [vars]
  {:store :database
   :migration-dir "migrations"
   :db {:classname    "com.mysql.jdbc.Driver"
        :subprotocol  "mysql"
        :subname      (:url vars)
        :user         (:user vars)
        :password     (:password vars)}})

(defn -main [& args]
  (-> (util/fetch-variables! variable-names) config mg/migrate))
