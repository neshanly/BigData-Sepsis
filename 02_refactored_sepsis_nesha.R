# ============================================================
# KODE REFACTOR - XGBoost untuk ehr_sepsis_dummy.csv
# Output dibuat lebih auditable + interpretabilitas prediksi
# ============================================================

# Install package sekali saja jika belum ada
packages <- c("xgboost", "caret", "dplyr")
missing_packages <- packages[!packages %in% rownames(installed.packages())]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(xgboost)
library(caret)
library(dplyr)

set.seed(123)

# ------------------------------------------------------------
# 1. Load data
# Dataset dummy memakai pemisah titik koma (;), jadi pakai sep = ";"
# Sesuaikan file_path jika file berada di folder lain.
# ------------------------------------------------------------

file_path <- "ehr_sepsis_dummy(1).csv"

# Jika file tidak ditemukan di folder kerja R, gunakan path alternatif.
# Silakan ubah sesuai lokasi file di laptop kamu.
if (!file.exists(file_path)) {
  file_path <- "C:/Users/NAZWA/Downloads/ehr_sepsis_dummy.csv"
}

ehr_raw <- read.csv(file_path, sep = ";", stringsAsFactors = FALSE)

# Cek struktur data awal
str(ehr_raw)

# ------------------------------------------------------------
# 2. Tentukan target dan fitur sesuai dataset dummy
# Target: sepsis_outcome, sudah berupa angka 0/1
#
# Catatan:
# icu_admission sengaja tidak dimasukkan sebagai fitur utama
# karena bisa menjadi data leakage jika ICU admission terjadi setelah kondisi sepsis diketahui.
# ------------------------------------------------------------

target_col <- "sepsis_outcome"

feature_cols <- c(
  "age",
  "sex",
  "temperature",
  "heart_rate",
  "respiratory_rate",
  "systolic_bp",
  "diastolic_bp",
  "wbc_count",
  "lactate",
  "creatinine",
  "oxygen_saturation",
  "comorbidity_diabetes",
  "comorbidity_ckd"
)

# Validasi kolom agar error lebih mudah dipahami
required_cols <- c(feature_cols, target_col)
missing_cols <- setdiff(required_cols, names(ehr_raw))

if (length(missing_cols) > 0) {
  stop(paste("Kolom berikut tidak ditemukan di dataset:", paste(missing_cols, collapse = ", ")))
}

# Ambil hanya kolom yang dipakai
d_model <- ehr_raw[, c(feature_cols, target_col)]

# Simpan nomor baris asli agar hasil prediksi dapat ditelusuri kembali
d_model$row_id <- seq_len(nrow(d_model))

# Hapus baris jika target kosong
d_model <- d_model[!is.na(d_model[[target_col]]), ]

# ------------------------------------------------------------
# 3. Tangani missing value
# Numerik: isi NA dengan median
# Kategorik: isi NA dengan modus
#
# Bagian ini juga membuat output audit:
# - preprocessing_missing_comparison.csv
# - plot_missing_before_after_preprocessing.png
# ------------------------------------------------------------

# Hitung missing value sebelum preprocessing
missing_before <- colSums(is.na(d_model[, c(feature_cols, target_col)]))

for (col in feature_cols) {

  if (is.numeric(d_model[[col]]) || is.integer(d_model[[col]])) {
    median_value <- median(d_model[[col]], na.rm = TRUE)
    d_model[[col]][is.na(d_model[[col]])] <- median_value
  } else {
    mode_value <- names(sort(table(d_model[[col]]), decreasing = TRUE))[1]
    d_model[[col]][is.na(d_model[[col]])] <- mode_value
    d_model[[col]] <- as.factor(d_model[[col]])
  }
}

# Pastikan target menjadi numeric 0/1
d_model[[target_col]] <- as.numeric(d_model[[target_col]])

# Hitung missing value sesudah preprocessing
missing_after <- colSums(is.na(d_model[, c(feature_cols, target_col)]))

preprocessing_missing_comparison <- data.frame(
  variabel = names(missing_before),
  missing_sebelum_preprocessing = as.numeric(missing_before),
  missing_sesudah_preprocessing = as.numeric(missing_after)
)

print(preprocessing_missing_comparison)

write.csv(
  preprocessing_missing_comparison,
  "preprocessing_missing_comparison.csv",
  row.names = FALSE
)

# Plot perbandingan sebelum dan sesudah preprocessing
png(
  filename = "plot_missing_before_after_preprocessing.png",
  width = 1200,
  height = 700
)

barplot(
  t(as.matrix(preprocessing_missing_comparison[, c(
    "missing_sebelum_preprocessing",
    "missing_sesudah_preprocessing"
  )])),
  beside = TRUE,
  names.arg = preprocessing_missing_comparison$variabel,
  las = 2,
  main = "Perbandingan Missing Value Sebelum dan Sesudah Preprocessing",
  ylab = "Jumlah Missing Value",
  cex.names = 0.8
)

legend(
  "topright",
  legend = c("Sebelum preprocessing", "Sesudah preprocessing"),
  fill = c("gray70", "gray30")
)

dev.off()

# ------------------------------------------------------------
# 4. One-hot encoding untuk kolom kategorik, terutama sex
# XGBoost butuh input matrix numerik
# ------------------------------------------------------------

# row_id tidak dimasukkan ke model karena hanya dipakai untuk audit/tracing
x <- model.matrix(sepsis_outcome ~ . - row_id - 1, data = d_model)
y <- d_model[[target_col]]
row_id <- d_model$row_id

# ------------------------------------------------------------
# 5. Split data train-test
# ------------------------------------------------------------

set.seed(123)

train_index <- createDataPartition(y, p = 0.8, list = FALSE)

x_train <- x[train_index, ]
x_test  <- x[-train_index, ]
y_train <- y[train_index]
y_test  <- y[-train_index]

row_id_train <- row_id[train_index]
row_id_test  <- row_id[-train_index]

# xgboost matrix
dtrain <- xgb.DMatrix(data = x_train, label = y_train)
dtest  <- xgb.DMatrix(data = x_test, label = y_test)

# ------------------------------------------------------------
# 6. Training model XGBoost
# ------------------------------------------------------------

param <- list(
  objective = "binary:logistic",
  eval_metric = "logloss",
  max_depth = 3,
  eta = 0.1
)

model <- xgb.train(
  params = param,
  data = dtrain,
  nrounds = 50,
  evals = list(train = dtrain, test = dtest),
  verbose = 0
)

# ------------------------------------------------------------
# 7. Prediksi dan evaluasi
# ------------------------------------------------------------

prob_pred <- predict(model, dtest)
class_pred <- ifelse(prob_pred >= 0.5, 1, 0)

hasil_prediksi <- data.frame(
  row_id = row_id_test,
  aktual = y_test,
  probabilitas_prediksi = prob_pred,
  kelas_prediksi = class_pred
)

print(head(hasil_prediksi))

# Simpan hasil prediksi agar output pipeline auditable
write.csv(
  hasil_prediksi,
  "hasil_prediksi_test.csv",
  row.names = FALSE
)

# Confusion matrix
evaluasi_confusion_matrix <- confusionMatrix(
  as.factor(class_pred),
  as.factor(y_test),
  positive = "1"
)

print(evaluasi_confusion_matrix)

# Simpan ringkasan evaluasi sederhana
evaluasi_ringkas <- data.frame(
  metrik = c("accuracy", "sensitivity", "specificity", "rata_rata_probabilitas_prediksi"),
  nilai = c(
    as.numeric(evaluasi_confusion_matrix$overall["Accuracy"]),
    as.numeric(evaluasi_confusion_matrix$byClass["Sensitivity"]),
    as.numeric(evaluasi_confusion_matrix$byClass["Specificity"]),
    mean(prob_pred)
  )
)

print(evaluasi_ringkas)

write.csv(
  evaluasi_ringkas,
  "evaluasi_ringkas_model.csv",
  row.names = FALSE
)

# ------------------------------------------------------------
# 8. Feature importance global
# Bagian ini menjelaskan fitur apa yang paling berpengaruh secara umum
# pada keseluruhan model.
# ------------------------------------------------------------

importance <- xgb.importance(
  feature_names = colnames(x),
  model = model
)

print(importance)

# Simpan feature importance global
write.csv(
  importance,
  "feature_importance_xgboost.csv",
  row.names = FALSE
)

# Plot feature importance global
png(
  filename = "plot_feature_importance_xgboost.png",
  width = 1000,
  height = 700
)

xgb.plot.importance(
  importance,
  main = "Feature Importance Global XGBoost"
)

dev.off()

# ------------------------------------------------------------
# 9. Interpretabilitas lokal dengan predcontrib = TRUE
# Selain feature importance global, predcontrib = TRUE dapat digunakan
# untuk melihat kontribusi masing-masing fitur pada prediksi pasien tertentu.
#
# Output ini mirip SHAP contribution:
# - nilai positif menaikkan peluang prediksi sepsis
# - nilai negatif menurunkan peluang prediksi sepsis
# - kolom BIAS adalah baseline kontribusi model
# ------------------------------------------------------------

feature_contribution <- predict(
  model,
  dtest,
  predcontrib = TRUE
)

feature_contribution <- as.data.frame(feature_contribution)

# Tambahkan row_id agar kontribusi fitur dapat ditelusuri ke pasien/baris data test
feature_contribution <- cbind(
  row_id = row_id_test,
  aktual = y_test,
  probabilitas_prediksi = prob_pred,
  kelas_prediksi = class_pred,
  feature_contribution
)

print(head(feature_contribution))

write.csv(
  feature_contribution,
  "feature_contribution_test.csv",
  row.names = FALSE
)

# ------------------------------------------------------------
# 10. Contoh interpretasi kontribusi fitur untuk satu pasien
# Bagian ini mengambil 1 pasien dari data test, lalu mengurutkan
# fitur berdasarkan kontribusi terbesarnya.
# ------------------------------------------------------------

pasien_ke <- 1

kontribusi_pasien <- feature_contribution[pasien_ke, ]

# Ambil hanya kolom kontribusi fitur, bukan metadata
kolom_metadata <- c("row_id", "aktual", "probabilitas_prediksi", "kelas_prediksi")
kontribusi_fitur <- kontribusi_pasien[, !(names(kontribusi_pasien) %in% kolom_metadata)]

kontribusi_fitur_long <- data.frame(
  fitur = names(kontribusi_fitur),
  kontribusi = as.numeric(kontribusi_fitur[1, ])
)

kontribusi_fitur_long <- kontribusi_fitur_long[order(abs(kontribusi_fitur_long$kontribusi), decreasing = TRUE), ]

print(kontribusi_fitur_long)

write.csv(
  kontribusi_fitur_long,
  "contoh_kontribusi_fitur_1_pasien.csv",
  row.names = FALSE
)

# Plot kontribusi fitur untuk satu pasien
png(
  filename = "plot_kontribusi_fitur_1_pasien.png",
  width = 1000,
  height = 700
)

barplot(
  kontribusi_fitur_long$kontribusi,
  names.arg = kontribusi_fitur_long$fitur,
  las = 2,
  main = "Kontribusi Fitur pada Prediksi Satu Pasien",
  ylab = "Nilai Kontribusi",
  cex.names = 0.8
)

abline(h = 0, lty = 2)

dev.off()

# ------------------------------------------------------------
# 11. Catatan output pipeline
# File yang dihasilkan:
# 1. preprocessing_missing_comparison.csv
# 2. plot_missing_before_after_preprocessing.png
# 3. hasil_prediksi_test.csv
# 4. evaluasi_ringkas_model.csv
# 5. feature_importance_xgboost.csv
# 6. plot_feature_importance_xgboost.png
# 7. feature_contribution_test.csv
# 8. contoh_kontribusi_fitur_1_pasien.csv
# 9. plot_kontribusi_fitur_1_pasien.png
# ------------------------------------------------------------
