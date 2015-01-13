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
  (let [is-valid-map (fn [m]
                       (do
                         (every? #(is (contains? m (keyword %))) (keys valid-request))
                         (is (contains? m :created_at))
                         (is (re-matches #"^\d+T\d+\.\d+Z$" (:created_at m)))
                         (is (contains? m ::sdb/id))
                         (is (re-matches #"^\d+$" (::sdb/id m)))))]

    (testing "with a minimum event request"
      (is-valid-map (db/create-event-map valid-request)))

    (testing "with an event request containing a log file"
      (let [m (->> {:log_file_digest "ade5...", :log_file_s3_url "s3://url"}
                   (merge valid-request)
                   (db/create-event-map))]
        (is-valid-map m)
        (is (contains? m :log_file_digest))
        (is (contains? m :log_file_s3_url))))

    (testing "with an event request containing a log file"
      (let [m (->> {:event_file_digest "ade5...", :event_file_s3_url "s3://url"}
                   (merge valid-request)
                   (db/create-event-map))]
        (is-valid-map m)
        (is (contains? m :event_file_s3_url))
        (is (contains? m :event_file_digest))))))
