(ns nucleotides.api.events-test
  (:require [clojure.test          :refer :all]
            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.metrics          :as metrics]
            [nucleotides.api.events           :as event]))


(use-fixtures :each (fn [f]
                      (do
                        (db/empty-database)
                        (apply fix/load-fixture (concat fix/base-fixtures [:unsuccessful-product-event]))
                        (f))))

(deftest nucleotides.api.events

  (testing "#exists?"
    (is (true?  (event/exists? 1)))
    (is (true?  (event/exists? "1")))
    (is (false? (event/exists? 1000)))
    (is (false? (event/exists? "1000")))
    (is (false? (event/exists? "unknown"))))

  (testing "valid?"

    (is (true? (event/valid? (mock-event :produce :failure))))
    (is (true? (event/valid? (mock-event :produce :success))))
    (is (true? (event/valid? (mock-event :evaluate :success))))
    (is (false? (event/valid? (mock-event :evaluate :invalid-file))))
    (is (false? (event/valid? (mock-event :evaluate :invalid-metric)))))

  (testing "#error-message"
    (is (= "Unknown file types in request: unknown"
           (event/error-message (mock-event :evaluate :invalid-file))))
    (is (= "Unknown metrics in request: unknown"
           (event/error-message (mock-event :evaluate :invalid-metric))))))
