(ns nucleotides.database.build-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc               :as db]
            [yesql.core                      :refer [defqueries]]
            [helper                          :as help]
            [nucleotides.database.build      :as build]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)
(defqueries "queryfile.sql" {:connection (con/create-connection)})

(def initial-test-data
  {:images
   [{"image_type"      "type",
     "description"     "description"
     "image_instances" {"image" "image/name"
                        "tasks" ["default" "careful"]}}]})

(defn refresh-migrate-load [f]
  (do
    (help/drop-all-tables)
    (build/migrate (con/create-connection) initial-test-data)
    (f)))

(deftest build

  (use-fixtures :once refresh-migrate-load)

  (testing "#migrate"
    (is (not (empty? (image-types))))))
