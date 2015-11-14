(ns nucleotides.api.benchmarks
  (:require [clojure.string            :as st]
            [clojure.data.json         :as json]
            [nucleotides.database.load :as db]))

(defn benchmark-entry [entry]
  {:id (:id entry)
   :image (select-keys entry [:name :task :sha256])
   :input (select-keys entry [:url :md5])})

(defn show
  "Returns all benchmarks, can be parameterised by completed or not."
  [db-client request]
   (let [params (:params request)]
      {:status 200
       :body   (->> {:connection db-client}
                    (db/benchmark-instances {})
                    (map benchmark-entry)
                    (json/write-str))}))
