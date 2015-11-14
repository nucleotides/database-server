(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [compojure.handler  :refer [site]]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]
            [ring.mock.request  :as mock]

            [nucleotides.database.connection  :as con]
            [nucleotides.database.load        :as db]
            [nucleotides.api.core             :as app]
            [helper                           :as help]

            ))

(help/silence-logging!)

(def database-client (con/create-connection))

(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (site (app/api database-client))]
     (hnd (mock/request method url params))))
  ([method url]
   (request method url {})))
