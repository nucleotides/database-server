(ns nucleotides.api.middleware-test
  (:require
    [clojure.test               :refer :all]
    [ring.mock.request          :as mock]
    [helper.event               :as ev]
    [nucleotides.api.middleware :as md]))


(deftest nucleotides.api.middleware

    (testing "parsing a json request body"
      (let [f #(-> (mock/request :get "/")
                   (mock/body %)
                   (mock/content-type "application/json")
                   ((md/middleware :body)))]

        (is (= (f "{\"a\" : 1}") {:a 1})))))
