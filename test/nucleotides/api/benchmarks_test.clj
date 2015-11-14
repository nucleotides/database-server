(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]
            [helper                           :as help]

            ))

(help/silence-logging!)

(defn show
  ([params] (bench/show (con/create-connection) params))
  ([]       (show {})))

(def first-entry-in-response
  (comp walk/keywordize-keys first json/read-str))

(deftest nucleotides.api.benchmarks

  (testing "#show"
    (testing "with a single benchmark entry"
      (let [_ (help/load-fixture "a_single_benchmark")
            {:keys [status body]} (show)]
        (is (= 200 status))
        (is (= 1 (count (json/read-str body))))

        (let [entry (first-entry-in-response body)]
          (is (contains? entry :id))
          (is (contains? entry :image))
          (is (= (entry :image)
                 {:name "image" :task "default" :sha256 "123456"}))
          (is (contains? entry :image))
          (is (= (entry :input)
                 {:url "s3://url" :md5 "123456"})))))))


