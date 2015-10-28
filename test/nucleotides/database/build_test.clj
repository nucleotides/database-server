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
  {:image
   [{"image_type"      "type",
     "description"     "description"
     "image_instances" {"image" "image/name"
                        "tasks" ["default" "careful"]}}]
   :data_type
   [{"name"     "data_name"
     "protocol" "data_protocol"
     "source"   "data_source"}]})


(use-fixtures :each (fn [f] (help/drop-tables) (f)))

(deftest build
  (testing "#migrate"
    (build/migrate (con/create-connection) initial-test-data)
    (is (= 1 (count (help/data-types))))
    (is (= 1 (count (help/image-types))))))
