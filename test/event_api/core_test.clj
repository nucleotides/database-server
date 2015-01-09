(ns event-api.core-test
  (:require [clojure.test      :refer :all]
            [ring.mock.request]
            [event-api.core]))

(defn request [method url params]
  (event-api.core/api (ring.mock.request/request method url params)))

(defn test-status-code [status-code response]
  (is (= (:status response) status-code)))

(defn test-body-match [re response]
  (is (re-matches re (:body response))))


(deftest post-events
  (let [req (partial request :post "/events")]

    (testing "post request with missing parameters"
      (test-status-code 422 (req {}))
      (test-status-code 422 (req {:benchmark_id "abcd"}))
      (test-status-code 422 (req {:benchmark_id        "abcd"
                                  :benchmark_type_code "000"
                                  :event_type_code     "000"})))

  (testing "post request with valid parameters"
    (let [response (req {:benchmark_id "abcd" :benchmark_type_code "0000"
                         :status_code  "0000" :event_type_code     "0000"})]
      (test-status-code 202 response)
      (test-body-match  #"^\d+$" response)))))
