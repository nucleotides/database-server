(ns nucleotides.api.benchmarks-test
  (:require [clojure.test                :refer :all]
            [helper.validation           :refer :all]
            [helper.fixture              :as fix]
            [helper.database             :as db]
            [nucleotides.api.benchmarks  :as bench]))

(deftest nucleotides.api.benchmarks

  (use-fixtures :each (fn [f]
                        (do
                          (db/empty-database)
                          (apply fix/load-fixture fix/base-fixtures)
                          (f))))

  (testing "#exists?"
    (is (true?  (bench/exists? "453e406dcee4d18174d4ff623f52dcd8")))
    (is (false? (bench/exists? "unknown")))))
