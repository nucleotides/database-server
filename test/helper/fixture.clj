(ns helper.fixture
  (:require [clojure.string                :as st]
            [camel-snake-kebab.core        :as ksk]
            [nucleotides.database.migrate  :as build]
            [helper.database               :as db]))

(defn test-directory [& paths]
  (->> paths
       (map ksk/->snake_case_string)
       (concat ["test"])
       (st/join "/")))

(defn load-fixture [& fixtures]
  (db/empty-database)
  (dorun
    (for [f fixtures]
      (db/exec-db-command (slurp (str "test/fixtures/" f ".sql"))))))
