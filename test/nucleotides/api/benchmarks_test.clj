(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]
            [helper                           :as help]))

(defn show
  ([params] (bench/show {:connection (con/create-connection)}
                        {:params params :query-params params}))
  ([]       (show {})))

(def lookup
  #(bench/lookup {:connection (con/create-connection)} % {}))

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
                 :metrics         {"ng50" 20000.0 "lg50" 10.0}}
            {:keys [status body]} (lookup id)]
        (is (= 200 status))
        (doall
          (for [k (keys exp)]
            (do (is (contains? body k))
                (is (= (k exp) (k body))))))))))
