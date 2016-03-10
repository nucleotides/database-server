(ns nucleotides.api.metrics-test
  (:require [clojure.test          :refer :all]

            [helper.database                  :as db]
            [helper.fixture                   :as fix]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.metrics          :as mt]))

(deftest nucleotides.api.metrics

  (testing "#invalid-metrics"
    (do
      (db/empty-database)
      (fix/load-fixture :metadata)
      (is (empty? (mt/invalid-metrics [:lg50])))
      (is (contains? (mt/invalid-metrics [:unknown]) "unknown")))))
