(ns nucleotides.api.events-test
  (:require [clojure.test                     :refer :all]
            [nucleotides.database.connection  :as con]
            [clojure.data.json                :as json]
            [nucleotides.api.events           :as event]
            [helper                           :as help]))

(def create
  #(event/create (con/create-connection) {:params %}))

(deftest nucleotides.api.events

  (testing "#create"

    (testing "a success product benchmark"
      (let [_ (help/load-fixture "a_single_benchmark")
            params {:id              "2f221a18eb86380369570b2ed147d8b4"
                    :benchmark_file  "s3://url"
                    :log_file        "s3://url"
                    :event_type      "product"
                    :success         "true"}
            {:keys [status body]} (create params)]
        (is (= 200 status))
        (is (= "1" body))
        (is (= 1 (help/table-length "benchmark-event")))))

    (testing "an unsuccessful product benchmark"
      (let [_ (help/load-fixture "a_single_benchmark")
            params {:id              "2f221a18eb86380369570b2ed147d8b4"
                    :log_file        "s3://url"
                    :event_type      "product"
                    :success         "false"}
            {:keys [status body]} (create params)]
        (is (= 200 status))
        (is (= "1" body))
        (is (= 1 (help/table-length "benchmark-event")))))

    (testing "an evaluation benchmark"
      (let [_ (help/load-fixture "a_single_benchmark_with_completed_product")
            params {:id              "2f221a18eb86380369570b2ed147d8b4"
                    :benchmark_file  "s3://url"
                    :log_file        "s3://url"
                    :event_type      "evaluation"
                    :success         "true"
                    :metrics         (json/write-str {"ng50" 10000 "lg50" 10})}
            {:keys [status body]} (create params)]
        (is (= 200 status))
        (is (= "2" body))
        (is (= 2 (help/table-length "benchmark-event")))
        (is (= 2 (help/table-length "metric-instance")))))))
