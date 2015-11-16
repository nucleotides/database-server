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
        (dorun
          (for [k [:id :image_task :image_name :image_sha256
                   :input_url :input_md5 :product :evaluation]]
            (is (contains? (first-entry-in-response body) k))))))))
