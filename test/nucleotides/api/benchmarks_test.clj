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

(def lookup
  #(bench/lookup (con/create-connection) % {}))

(def long->wide
  (comp (filter #(nil? %1)) (partial apply hash-map) flatten (partial map vals)))

(long->wide (bench/metrics-by-benchmark-id
              {:id "2f221a18eb86380369570b2ed147d8b4"}
              {:connection (con/create-connection)}))


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
        (is (= "1" body))
        (is (= 1 (help/table-length "benchmark-event"))))))

  (testing "#lookup"

    (testing "an incomplete benchmark"
      (let [_   (help/load-fixture "a_single_benchmark")
            id  "2f221a18eb86380369570b2ed147d8b4"
            exp {:id              "2f221a18eb86380369570b2ed147d8b4"
                 :image_name      "image"
                 :image_sha256    "123456"
                 :image_task      "default"
                 :input_md5       "123456"
                 :input_url       "s3://url"
                 :product         false
                 :product_url     nil
                 :evaluation      false
                 :metrics         {}}
            {:keys [status body]} (lookup id)]
        (is (= 200 status))
        (doall
          (for [k (keys exp)]
            (do (is (contains? body k))
                (is (= (k exp) (k body))))))))

    (testing "a complete benchmark"
      (let [_   (help/load-fixture "a_single_benchmark_with_completed_evaluation")
            id  "2f221a18eb86380369570b2ed147d8b4"
            exp {:id              "2f221a18eb86380369570b2ed147d8b4"
                 :image_name      "image"
                 :image_sha256    "123456"
                 :image_task      "default"
                 :input_md5       "123456"
                 :input_url       "s3://url"
                 :product         true
                 :product_url     "s3://url"
                 :evaluation      true
                 :metrics         {"ng50" 20000.0 "l50" 10.0}}
            {:keys [status body]} (lookup id)]
        (is (= 200 status))
        (doall
          (for [k (keys exp)]
            (do (is (contains? body k))
                (is (= (k exp) (k body))))))))))
