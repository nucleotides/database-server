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

(def has-benchmark-fields
  (juxt
    (resp/does-http-body-contain [:id :complete :type :tasks])
    (partial resp/does-http-body-not-contain [:task_id])))

(def has-task-fields
  (let [f (juxt
            #(is (not (empty? %)))
            #(dorun
               (for [task %]
                 (dorun
                   (for [k [:id :type :complete :image :inputs]]
                     (is (contains? task k)))))))]
    (partial resp/dispatch-response-body-test f [:tasks])))

(defn test-get-benchmark [{:keys [fixtures tests complete]}]
  (let [base-tests [resp/is-ok-response
                    has-benchmark-fields
                    has-task-fields
                    #(is (= (get-in % [:body :complete]) complete))]]
    (resp/test-response
      {:api-call #(bench/lookup {:connection (con/create-connection)} "453e406dcee4d18174d4ff623f52dcd8" {})
       :fixtures (concat fix/base-fixtures fixtures)
       :tests    (concat base-tests tests)})))

(deftest nucleotides.api.benchmarks

  (testing "#lookup"

    (testing "a benchmark with no completed tasks"
      (test-get-benchmark {:complete false}))

    (testing "a benchmark with an unsuccessful produce event"
      (test-get-benchmark
        {:complete true
         :fixtures [:successful_product_event :successful_evaluate_event]}))))
