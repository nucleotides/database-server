(ns nucleotides.api.benchmarks-test
  (:require [clojure.test          :refer :all]
            [yesql.core            :refer [defqueries]]
            [com.rpl.specter          :refer :all]

            [helper.fixture        :as fix]
            [helper.database       :as db]
            [helper.http-response  :as resp]
            [helper.image          :as image]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]))

(defn test-get-benchmark [{:keys [fixtures tests complete]}]
  (let [base-tests [resp/is-ok-response
                    (partial resp/does-http-body-contain [:id :name :image])
                    image/has-image-metadata
                    #(is (= (get-in % [:body :complete]) complete))]]
   (resp/test-response
    {:api-call #(bench/lookup {:connection (con/create-connection)} "2f221a18eb86380369570b2ed147d8b4" {})
     :fixtures (concat fix/base-fixtures fixtures)
     :tests    (concat base-tests tests)})))

(comment (deftest nucleotides.api.benchmarks

  (testing "#lookup"

    (testing "a benchmark with no events"
      (test-get-benchmark {:complete false}))

    (testing "a benchmark with an unsuccessful produce event"
      (test-get-benchmark
        {:complete false
         :fixtures [:unsuccessful_product_event]
         :tests    [#(resp/contains-file-entries % [:body :events 0 :files])]})))))
