(ns event-api.database-test
  (:require [clojure.test :refer :all]
            [cemerick.rummage   :as sdb]
            [event-api.database :as db]))

(def valid-request
  {"benchmark_id"        "abcd"
   "benchmark_type_code" "0000"
   "status_code"         "0000"
   "event_type_code"     "0000"})


(deftest valid-event?

  (testing "an event hash with missing values"
    (is (= false (db/valid-event? {})))
    (is (= false (db/valid-event? {"benchmark_id" "abcd"})))
    (is (= false (db/valid-event? {"benchmark_id"        "abcd"
                                   "benchmark_type_code" "0000"
                                   "event_type_code"     "0000"})))))

   (testing "an event hash with all required values"
    (is (= true (db/valid-event? valid-request))))

(deftest create-event-map
  (let [m (db/create-event-map valid-request)]
    (is (re-matches #"^\d+$" (::sdb/id m))
    (every? #(is (contains? m (keyword %))) (keys valid-request)))))
