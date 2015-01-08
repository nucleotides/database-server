(ns event-api.core-test
  (:require [clojure.test      :refer :all]
            [ring.mock.request]
            [event-api.core]))

(defn request [method url params]
  (event-api.core/api (ring.mock.request/request method url params)))

(defn test-req [r status-code]
  (let [response (apply request r)]
    (is (= (:status response) status-code))))

(deftest post-events

  (testing "post request with missing parameters"
    (let [f (fn [params] (test-req [:post "/events" params] 422))]
      (f {})
      (f {:benchmark_id "abcd"})
      (f {:benchmark_id "abcd" :benchmark_type_code "000" :event_type_code "000"})))

  (testing "post request with valid parameters"
    (let [f (fn [params] (test-req [:post "/events" params] 202))]
      (f {:benchmark_id "abcd" :benchmark_type_code "0000"
          :status_code  "0000" :event_type_code     "0000"}))))
