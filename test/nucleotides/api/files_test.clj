(ns nucleotides.api.files-test
  (:require [clojure.test          :refer :all]

            [helper.database                  :as db]
            [helper.fixture                   :as fix]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.files            :as files]))


(use-fixtures :each (fn [f]
                      (do
                        (db/empty-database)
                        (apply fix/load-fixture
                               (concat fix/base-fixtures
                                       [:unsuccessful_product_event :unsuccessful_evaluate_event]))
                        (f))))

(deftest nucleotides.api.files

  (testing "#invalid-files"
    (is (empty? (files/invalid-files ["contig_fasta"])))
    (is (contains? (files/invalid-files ["unknown"]) "unknown")))

  (testing "#create-event-file-instance<!"

    (testing "#creating-a-duplicate-files"
      (let [f  #(files/create-event-file-instance<!
                  {:url "s3://contigs", :sha256 "f7455", :type "contig_fasta" :event_id %}
                  {:connection (con/create-connection)})]
        (f 1)
        (f 2)))))
