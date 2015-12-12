(ns helper.fixture
  (:require [camel-snake-kebab.core        :as ksk]
            [nucleotides.database.migrate  :as build]
            [helper.database               :as db]))

(defn test-directory [which]
  (str "test/" (ksk/->snake_case_string which)))

(defn test-directory-file [which file]
  (-> (test-directory which)
      (str file)
      (clojure.java.io/file)
      (.getCanonicalPath)))

(defn fetch-test-data [x]
  (build/load-data-file (test-directory :data) x))

(defn load-fixture [x]
  (do (db/empty-database)
      (db/exec-db-command (slurp (str "test/fixtures/" x ".sql")))))
