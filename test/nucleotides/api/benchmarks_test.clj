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
