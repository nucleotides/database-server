(ns event-api.database-test
  (:require [clojure.test :refer :all]
            [cemerick.rummage   :as sdb]
            [event-api.database :as db]))

(def valid-request
  {:benchmark_id        "abcd"
   :benchmark_type_code "0000"
   :status_code         "0000"
   :event_type_code     "0000"})



(deftest valid-event?

  (testing "an event hash with missing values"
    (is (= false (db/valid-event? {})))
    (is (= false (db/valid-event? {:benchmark_id "abcd"})))
    (is (= false (db/valid-event? {:benchmark_id        "abcd"
                                   :benchmark_type_code "0000"
                                   :event_type_code     "0000"})))))

   (testing "an event hash with all required values"
    (is (= true (db/valid-event? valid-request))))



(deftest missing-paramters

  (testing "an event hash with missing values"
    (is (= #{:benchmark_id :benchmark_type_code :status_code :event_type_code}
           (db/missing-parameters {})))

    (is (= #{:benchmark_type_code :status_code :event_type_code}
           (db/missing-parameters {:benchmark_id "0000"})))

    (is (= #{:status_code :event_type_code}
           (db/missing-parameters {:benchmark_id "0000", :benchmark_type_code "0000"}))

    (is (= #{}
           (db/missing-parameters {:benchmark_id        "abced",
                                   :benchmark_type_code "0000"
                                   :event_type_code     "0000"
                                   :status_code         "0000"}))))))


(deftest create-event-map
  (let [m (db/create-event-map valid-request)]
    (do
      (every? #(is (contains? m (keyword %))) (keys valid-request))

      (is (contains? m :created_at))
      (is (re-matches #"^\d+T\d+\.\d+Z$" (:created_at m)))

      (is (contains? m ::sdb/id))
      (is (re-matches #"^\d+$" (::sdb/id m))))))
