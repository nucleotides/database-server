(ns nucleotides.database.migrate-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc               :as db]
            [yesql.core                      :refer [defqueries]]
            [helper                          :as help]
            [nucleotides.database.migrate    :as migrate]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(use-fixtures :each (fn [f] (help/drop-tables) (f)))

(def expected-lengths
  [[:image-type         2]
   [:image-task         4]
   [:data-type          1]
   [:data-instance      3]
   [:benchmark-type     2]
   [:benchmark-instance 12]
   [:metric-type        1]])

(deftest migrate
  (testing "-main"
    (migrate/migrate help/test-data-directory)
    (doall (for [[table-name length] expected-lengths]
             (is (= length (help/table-length table-name)))))))
