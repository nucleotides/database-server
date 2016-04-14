(ns helper.database
  (:require [clojure.java.jdbc               :as sql]
            [taoensso.timbre                 :as log]
            [migratus.core                   :as mg]
            [camel-snake-kebab.core          :as ksk]
            [nucleotides.database.connection :as con]
            [nucleotides.database.migrate    :as build]))

(log/set-config! [:appenders :standard-out :enabled? false])

; Turn off logging for c3p0
(System/setProperties
  (doto (java.util.Properties. (System/getProperties))
    (.put "com.mchange.v2.log.MLog" "com.mchange.v2.log.FallbackMLog")
    (.put "com.mchange.v2.log.FallbackMLog.DEFAULT_CUTOFF_LEVEL" "OFF")))

(defn exec-db-command [command]
  (sql/with-db-connection [conn (con/create-connection)]
    (with-open [s (.createStatement (:connection conn))]
      (.execute s command))))

(defn drop-tables []
  (do
    (exec-db-command "drop schema public cascade;")
    (exec-db-command "create schema public;")))

(defn empty-database []
  (do
    (drop-tables)
    (mg/migrate (build/create-migratus-spec))))

(defn table-entries [table-name]
  (sql/query
    (con/create-connection)
    (apply str "select * from " (ksk/->snake_case_string table-name))))

(defn metadata-entries [table-name]
  (sql/query
    (con/create-connection)
    (apply str "select * from " (ksk/->snake_case_string table-name) "_type")))

(def table-length
  (comp count table-entries))

(def metadata-length
  (comp count metadata-entries))
