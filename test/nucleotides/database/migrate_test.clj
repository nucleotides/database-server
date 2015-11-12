(ns nucleotides.database.migrate-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc               :as db]
            [yesql.core                      :refer [defqueries]]
            [helper                          :as help]
            [nucleotides.database.migrate    :as migrate]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(use-fixtures :each (fn [f] (help/drop-tables) (f)))

(def expected-lengths
  [[:image-type     2]
   [:image-task     4]
   [:data-type      1]
   [:data-instance  4] ;3
   [:benchmark-type 2]])

(deftest migrate
  (testing "-main"
    (migrate/migrate help/test-data-directory)
    (for [[table-name length] expected-lengths]
      (is (= length (help/table-length table-name))))))
