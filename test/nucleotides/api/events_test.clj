(ns nucleotides.api.events-test
  (:require [clojure.test          :refer :all]
            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.events           :as ev]))

(deftest nucleotides.api.events)
