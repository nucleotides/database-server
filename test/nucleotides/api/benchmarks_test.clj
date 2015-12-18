(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [helper.fixture        :refer :all]
            [helper.http-response  :refer :all]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]))

(def lookup
  #(bench/lookup {:connection (con/create-connection)} % {}))

(defn has-image-metadata [res]
  (is (= (get-in res [:body :name]) "benchmark_name"))
  (is (= (get-in res [:body :image :name]) "bioboxes/velvet"))
  (is (= (get-in res [:body :image :sha256]) "123abc"))
  (is (= (get-in res [:body :image :task]) "default")))


(deftest nucleotides.api.benchmarks

  (testing "#lookup"

    (testing "an incomplete benchmark"
      (let [_    (load-fixture "a_single_incomplete_task")
            id   "2f221a18eb86380369570b2ed147d8b4"
            res  (lookup id)]
        (is-ok-response res)
        (has-image-metadata res)
        (is (= id (get-in res [:body :id])))))

    (testing "an benchmark with a successful product event"
      (let [_    (load-fixture "a_single_incomplete_task"
                               "a_successful_product_event")
            id   "2f221a18eb86380369570b2ed147d8b4"
            res  (lookup id)]
        (is-ok-response res)
        (has-image-metadata res)
        (is (= id (get-in res [:body :id])))
        (is (= (get-in res [:body :product :url]) "s3://url"))
        (is (= (get-in res [:body :product :md5]) "123abc"))
        (is (= (get-in res [:body :product :log]) "s3://url"))))))
