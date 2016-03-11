(ns nucleotides.api.files-test
  (:require [clojure.test          :refer :all]

            [helper.database                  :as db]
            [helper.fixture                   :as fix]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.files            :as files]))

(deftest nucleotides.api.files

  (use-fixtures :each (fn [f]
                        (do
                          (db/empty-database)
                          (fix/load-fixture :metadata)
                          (f))))

  (testing "#invalid-files"
    (is (empty? (files/invalid-files ["contig_fasta"])))
    (is (contains? (files/invalid-files ["unknown"]) "unknown"))))
