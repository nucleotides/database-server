(ns event-api.database-test
  (:require [clojure.test :refer :all]
            [event-api.database :as db]))


(deftest valid-event?

  (testing "an event hash with missing values"
    (is (= false (db/valid-event? {})))
    (is (= false (db/valid-event? {"benchmark_id" "abcd"})))
    (is (= false (db/valid-event? {"benchmark_id"        "abcd"
                                   "benchmark_type_code" "0000"
                                   "event_type_code"     "0000"})))))

   (testing "an event hash with all required values"
    (is (= true (db/valid-event? {"benchmark_id"        "abcd"
                                  "benchmark_type_code" "0000"
                                  "status_code"         "0000"
                                  "event_type_code"     "0000"}))))

(deftest generate-event-id
  (is (re-matches #"^\d+$" (db/generate-event-id))))
