(ns event-api.core-test
  (:require [clojure.test      :refer :all]
            [ring.mock.request]
            [event-api.core]))

(defn request [method url]
  (event-api.core/api (ring.mock.request/request method url)))

(deftest events
  (is (= (:status (request :get "/events")) 200)))
