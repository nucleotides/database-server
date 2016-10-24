(ns nucleotides.api.middleware
  (:require
    [ring.logger.timbre             :refer [wrap-with-logger]]
    [ring.middleware.params         :refer [wrap-params]]
    [ring.middleware.keyword-params :refer [wrap-keyword-params]]
    [ring.middleware.json           :refer [wrap-json-response wrap-json-body]]))

(defn middleware [handler]
  (-> handler
      (wrap-keyword-params)
      (wrap-params)
      (wrap-json-response)
      (wrap-json-body {:keywords? true})
      (wrap-with-logger)))
