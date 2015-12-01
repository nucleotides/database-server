(ns nucleotides.api.middleware
  (:require [compojure.handler               :refer [api]]
            [ring.logger.timbre              :refer [wrap-with-logger]]
            [ring.middleware.json            :refer [wrap-json-response]]))

(defn middleware [handler]
  (-> handler
      (wrap-json-response)
      (wrap-with-logger)
      (api)))
