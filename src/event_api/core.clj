(ns event-api.core
  (:require [compojure.core         :refer [GET POST defroutes]]
            [clojure.set            :refer [superset?]]
            [ring.middleware.params :refer [wrap-params]]))

(defn post-event
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [request]
  (let [required-params #{"benchmark_id"
                          "benchmark_type_code"
                          "status_code"
                          "event_type_code"}
        request-params  (set (keys (:params request)))]
    (if (superset? request-params required-params)
      {:status 202}
      {:status 422})))

(defroutes routes
  (POST "/events" [] post-event))

(def api (wrap-params routes))
