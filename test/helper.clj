(ns helper
  (:require [clojure.java.jdbc               :as sql]
            [clojure.string                  :as string]
            [taoensso.timbre                 :as log]
            [migratus.core                   :as mg]
            [nucleotides.database.migrate    :as build]
            [nucleotides.database.connection :as con]))

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
  (let [con            (con/create-connection)
        formatted-name (-> (str table-name)
                           (string/replace  "-" "_")
                           (string/replace  ":" ""))]
    (sql/query con (apply str "select * from " formatted-name))))

(def table-length
  (comp count table-entries))

(def test-data-directory
  (.getCanonicalPath (clojure.java.io/file "test/data")))

(def fetch-test-data
  (partial build/load-data-file test-data-directory))

(defn load-fixture [x]
  (do (empty-database)
      (exec-db-command (slurp (str "test/fixtures/" x ".sql")))))
