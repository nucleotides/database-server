(ns event-api.core
  (:require [compojure.core         :refer [GET POST routes]]
            [ring.middleware.params :refer [wrap-params]]
            [event-api.database     :as db]
            [event-api.server       :as server]))

(defn get-credentials []
  [(System/getenv "AWS_ACCESS_KEY")
   (System/getenv "AWS_SECRET_KEY")
   "https://sdb.us-west-1.amazonaws.com"])

(defn get-domain []
   (System/getenv "AWS_SDB_DOMAIN"))

(defn api []
  (let [client (apply db/create-client (get-credentials))
        domain (get-domain)]
    (wrap-params
      (routes
        (POST "/events" [] (partial server/post-event client domain))))))
