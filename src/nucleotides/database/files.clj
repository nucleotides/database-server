(ns nucleotides.database.files
  (:require
    [clojure.java.io         :as io]
    [clojure.string          :as st]
    [clj-yaml.core           :as yaml]
    [camel-snake-kebab.core  :as ksb]))


(def filename->keyword
  #(-> (.getName %)
       (st/replace ".yml" "")
       (ksb/->kebab-case-keyword)))

(def list-yaml-files
  (comp (partial filter #(.endsWith (.getName %) ".yml"))
        file-seq
        io/file))

(defn get-dataset-map
  "Loads all YAML files from a given directory"
  [directory]
  (->> directory
       (list-yaml-files)
       (map (juxt filename->keyword (comp yaml/parse-string slurp)))
       (into {})))

(defn load-data-files [directory]
  (let [f #(get-dataset-map (str directory %))]
    {:cv      (f "/controlled_vocabulary")
     :inputs  (f "/inputs")
     :data    (f "/inputs/data")}))
