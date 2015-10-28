(ns helper
  (:require [clojure.java.jdbc               :as sql]
            [taoensso.timbre                 :as log]
            [migratus.core                   :as mg]
            [yesql.core                      :refer [defqueries]]
            [nucleotides.database.build      :as build]
            [nucleotides.database.connection :as con]))

(defqueries "queryfile.sql" {:connection (con/create-connection)})

(defn silence-logging! []
  (log/set-config! [:appenders :standard-out :enabled? false]))

(defn exec-db-command [command]
  (sql/with-db-connection [conn (con/create-connection)]
    (with-open [s (.createStatement (:connection conn))]
      (.executeUpdate s command))))

(defn drop-tables []
  (do
    (exec-db-command "drop schema public cascade;")
    (exec-db-command "create schema public;")))

(defn empty-database []
  (do
    (drop-tables)
    (mg/migrate (build/create-migratus-spec (con/create-connection)))))

(def test-data-directory
  (.getCanonicalPath (clojure.java.io/file "test/data")))
