(ns event-api.core-test
  (:require [clojure.test :refer :all]
            [ring.mock.request  :as mock]
            [cemerick.rummage   :as sdb]
            [event-api.database :as db]
            [event-api.core     :as app]))

(def domain "event-dev")
(def client (db/create-client "dummy" "dummy" "http://192.168.59.103:8081"))
(def api (app/api client domain))

(defn sdb-domain-fixture [f]
  (do
    (sdb/create-domain client domain)
    (f)
    (sdb/delete-domain client domain)))

(use-fixtures
  :once sdb-domain-fixture)
