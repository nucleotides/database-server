(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]
            [helper                           :as help]))

(defn show
  ([params] (bench/show (con/create-connection) {:params params :query-params params}))
  ([]       (show {})))

(def create
  #(bench/create (con/create-connection) {:params %}))



(deftest nucleotides.api.benchmarks

  (testing "#show"

    (testing "with a single benchmark entry"
      (let [_ (help/load-fixture "a_single_benchmark")]

        (testing "with no request parameter"
          (let [{:keys [status body]} (show)]
            (is (= 200 status))
            (is (not (empty? body)))
            (dorun
              (for [k [:id :image_task :image_name :image_sha256
                       :input_url :input_md5 :product :evaluation]]
                (is (contains? (first body) k))))))

        (testing "with product=false request parameter"
          (let [{:keys [status body]} (show {:product "false"})]
            (is (= 200 status))
            (is (not (empty? body)))
            (dorun
              (for [k [:id :image_task :image_name :image_sha256
                       :input_url :input_md5 :product :evaluation]]
                (is (contains? (first body) k))))))

        (testing "with product=true request parameter"
          (let [{:keys [status body]} (show {:product "true"})]
            (is (= 200   status))
            (is (empty?  body)))))))

  (testing "#create"

    (testing "with a product benchmark"
      (let [_ (help/load-fixture "a_single_benchmark")
            params {:id              "2f221a18eb86380369570b2ed147d8b4"
                    :benchmark_file  "s3://url"
                    :log_file        "s3://url"
                    :event_type      "product"
                    :success         "true"}
            {:keys [status body]} (create params)]
        (is (= 201 status))
        (is (= 1 body))
        (is (= 1 (help/table-length "benchmark-event")))))))
