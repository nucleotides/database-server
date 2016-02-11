(ns nucleotides.api.middleware
  (:require
    [compojure.handler    :refer [api]]
    [ring.logger.timbre   :refer [wrap-with-logger]]
    [ring.middleware.json :refer [wrap-json-response wrap-json-body]]))

(defn middleware [handler]
  (-> handler
      (wrap-json-response)
      (wrap-json-body {:keywords? true})
      (wrap-with-logger)
      (api)))
