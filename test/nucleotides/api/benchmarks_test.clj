(ns nucleotides.api.benchmarks-test
  (:require [clojure.test                :refer :all]
            [helper.validation           :refer :all]
            [helper.fixture              :as fix]
            [helper.database             :as db]
            [helper.http-response        :as resp]
            [nucleotides.api.benchmarks  :as bench]))

(def has-benchmark-fields
  (juxt
    (resp/does-http-body-contain [:id :complete :type :tasks])
    (partial resp/does-http-body-not-contain [:task_id])))


(def has-task-fields
  (let [f (juxt
            #(is (not (empty? %)))
            #(dorun
               (for [task %]
                 (do
                   (dorun
                     (for [k [:id :type :complete :image :inputs]]
                       (is (contains? task k))))
                   (is-valid-image? (:image task))))))]
    (partial resp/dispatch-response-body-test f [:tasks])))


(deftest nucleotides.api.benchmarks

  (use-fixtures :each (fn [f]
                        (do
                          (db/empty-database)
                          (apply fix/load-fixture fix/base-fixtures)
                          (f))))

  (testing "#exists?"
    (is (true?  (bench/exists? "453e406dcee4d18174d4ff623f52dcd8")))
    (is (false? (bench/exists? "unknown")))))
