(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [helper.fixture        :refer :all]
            [helper.http-response  :refer :all]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.events           :as event]
            [nucleotides.api.benchmarks       :as bench]))

(def lookup
  #(bench/lookup {:connection (con/create-connection)} % {}))

(defn has-image-metadata [res]
  (is (= (get-in res [:body :name]) "benchmark_name"))
  (is (= (get-in res [:body :image :name]) "bioboxes/velvet"))
  (is (= (get-in res [:body :image :sha256]) "123abc"))
  (is (= (get-in res [:body :image :task]) "default")))


(defn has-file [res & file-paths]
  (let [paths {:url "s3://url", :md5 "123abc" :log "s3://url"}]
    (dorun
      (for [[k value] paths]
        (is (= value
               (->> [:body file-paths k]
                    (flatten)
                    (get-in res))))))))

(def benchmark-id "2f221a18eb86380369570b2ed147d8b4")

(comment (deftest nucleotides.api.benchmarks

  (testing "#lookup"

    (testing "an incomplete benchmark"
      (let [_    (load-fixture "a_single_incomplete_task")
            res  (lookup benchmark-id)]
        (is-ok-response res)
        (has-image-metadata res)
        (is (= benchmark-id (get-in res [:body :id])))
        (is (= nil (get-in res [:body :product])))
        (is (= []  (get-in res [:body :evaluate])))
        (is (= {}  (get-in res [:body :metrics])))))

    (testing "an benchmark with a successful product event"
      (let [_    (load-fixture "a_single_incomplete_task"
                               "a_successful_product_event")
            res  (lookup benchmark-id)]
        (is-ok-response res)
        (has-image-metadata res)
        (has-file res :product)
        (is (= benchmark-id (get-in res [:body :id])))))

    (testing "an benchmark with a successful evaluate event"
      (let [_    (load-fixture "a_single_incomplete_task"
                               "a_successful_product_event"
                               "a_successful_evaluate_event")
            res  (lookup benchmark-id)]
        (is-ok-response res)
        (is (= benchmark-id (get-in res [:body :id])))
        (has-image-metadata res)
        (has-file res :product)
        (has-file res :evaluate 0)
        (is (= 5.0 (get-in res [:body :metrics "ng50"])))
        (is (= 20000.0 (get-in res [:body :metrics "lg50"]))))))))
