(ns helper.database
  (:require [clojure.java.jdbc               :as sql]
            [clojure.string                  :as string]
            [taoensso.timbre                 :as log]
            [migratus.core                   :as mg]
            [camel-snake-kebab.core          :as ksk]
            [nucleotides.database.connection :as con]
            [nucleotides.database.migrate    :as build]))

(log/set-config! [:appenders :standard-out :enabled? false])

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
    (mg/migrate (build/create-migratus-spec (con/create-connection)))))

(defn table-entries [table-name]
  (sql/query
    (con/create-connection)
    (apply str "select * from " (ksk/->snake_case_string table-name))))

(defn metadata-entries [metadata-name]
  (sql/query
    (con/create-connection)
    (apply str "select * from metadata where category = '" (ksk/->snake_case_string metadata-name) "'")))

(def table-length
  (comp count table-entries))

(def metadata-length
  (comp count metadata-entries))
