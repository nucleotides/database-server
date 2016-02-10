(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]

            [helper.fixture        :as fix]
            [helper.database       :as db]
            [helper.http-response  :as resp]
            [helper.image          :as image]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]))

(defn test-get-benchmark [{:keys [extra-fixtures tests complete]}]
  (resp/test-response
    {:api-call #(bench/lookup {:connection (con/create-connection)} "2f221a18eb86380369570b2ed147d8b4" {})
     :fixtures (concat fix/base-fixtures extra-fixtures)
     :tests    [resp/is-ok-response
                (partial resp/does-http-body-contain [:id :name :image])
                image/has-image-metadata
                #(is (= (get-in % [:body :complete]) complete))]}))

(deftest nucleotides.api.benchmarks

  (testing "#lookup"

    (testing "a benchmark with no events"
      (test-get-benchmark {:complete false}))))
