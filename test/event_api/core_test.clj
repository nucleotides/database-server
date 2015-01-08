(ns event-api.core-test
  (:require [clojure.test      :refer :all]
            [ring.mock.request]
            [event-api.core]))

(defn request [method url params]
  (event-api.core/api (ring.mock.request/request method url params)))

(defn test-request [r status-code]
  (let [response (apply request r)]
    (is (= (:status response) status-code))))

(deftest events
  (test-request [:post "/events" {}] 422))
