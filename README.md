# Pipeline Prediksi Risiko Sepsis EHR

Repository ini berisi project sederhana untuk tugas **Implementasi, Audit, dan Penalaran Klinis dalam Big Data Kesehatan**. Project ini menggunakan dataset dummy Electronic Health Record (EHR) untuk membuat pipeline prediksi risiko sepsis menggunakan algoritma XGBoost di R.

Tujuan utama project ini bukan hanya membuat model prediksi, tetapi juga menunjukkan bagaimana kode analisis data kesehatan dapat dibuat lebih rapi, mudah dijalankan ulang, auditable, dan lebih mudah dijelaskan kepada pengguna klinis.

## Deskripsi Singkat Project

Dataset yang digunakan adalah dataset dummy EHR sepsis. Data ini berisi informasi pasien seperti usia, jenis kelamin, tanda vital, hasil laboratorium, komorbiditas, status ICU, dan outcome sepsis.

Model yang digunakan adalah XGBoost dengan target prediksi `sepsis_outcome`. Variabel `icu_admission` tidak dimasukkan sebagai fitur utama karena berpotensi menjadi data leakage, yaitu informasi yang dapat muncul setelah kondisi klinis pasien diketahui.

## Struktur File

| Nama File | Keterangan |
|---|---|
| `01_bad_wrangle.R` | Skrip awal dengan kualitas kode yang masih buruk. File ini digunakan sebagai tahap awal sebelum proses refactoring. |
| `02_refactored_sepsis_pipeline_auditable_interpretable.R` | Skrip hasil refactoring yang sudah lebih rapi, memiliki komentar, validasi kolom, output audit, dan interpretabilitas model. |
| `ehr_sepsis_dummy.csv` | Dataset dummy EHR yang digunakan sebagai input analisis. |
| `README.md` | Dokumentasi utama repository. |
| `data_dictionary.md` | Penjelasan variabel dalam dataset. |
| `preprocessing_missing_comparison.csv` | Output perbandingan jumlah missing value sebelum dan sesudah preprocessing. |
| `hasil_prediksi_test.csv` | Output hasil prediksi model pada data test. |
| `evaluasi_ringkas_model.csv` | Output ringkasan evaluasi model. |
| `feature_importance_xgboost.csv` | Output feature importance global dari model XGBoost. |
| `feature_contribution_test.csv` | Output kontribusi fitur pada prediksi pasien di data test. |
| `contoh_kontribusi_fitur_1_pasien.csv` | Contoh kontribusi fitur untuk satu pasien. |
| `plot_missing_before_after_preprocessing.png` | Visualisasi missing value sebelum dan sesudah preprocessing. |
| `plot_feature_importance_xgboost.png` | Visualisasi feature importance global. |
| `plot_kontribusi_fitur_1_pasien.png` | Visualisasi kontribusi fitur pada satu pasien. |

## Software dan Package

Project ini dijalankan menggunakan R dengan package berikut:

```r
xgboost
caret
dplyr
```

Jika package belum tersedia, jalankan perintah berikut di RStudio:

```r
install.packages("xgboost")
install.packages("caret")
install.packages("dplyr")
```

## Cara Menjalankan Project

1. Download atau clone repository ini.
2. Pastikan file dataset `ehr_sepsis_dummy.csv` berada dalam folder yang sama dengan file R.
3. Buka RStudio.
4. Set working directory ke folder repository.
5. Jalankan file refactoring berikut:

```r
source("02_refactored_sepsis_pipeline_auditable_interpretable.R")
```

Setelah kode dijalankan, file output dalam bentuk CSV dan PNG akan tersimpan otomatis di working directory.

## Alur Pipeline

Pipeline analisis dalam project ini terdiri dari beberapa tahap:

1. Membaca dataset dummy EHR.
2. Menentukan target dan fitur yang digunakan.
3. Menghapus baris dengan target kosong.
4. Menangani missing value menggunakan median untuk variabel numerik dan modus untuk variabel kategorik.
5. Melakukan one-hot encoding untuk variabel kategorik.
6. Membagi data menjadi data latih dan data uji.
7. Melatih model XGBoost.
8. Melakukan prediksi dan evaluasi model.
9. Menyimpan output prediksi, evaluasi, feature importance, dan kontribusi fitur.
10. Membuat visualisasi untuk mendukung audit dan interpretasi model.

## Audit Git

Repository ini dibuat dengan beberapa tahap commit agar proses perubahan kode dapat ditelusuri.

Tahapan commit yang digunakan:

1. `initial commit: data wrangling script for sepsis risk`  
   Berisi kode awal yang masih kurang rapi.

2. `Refactor: improve comprehensibility and auditability`  
   Berisi kode hasil refactoring yang lebih mudah dipahami dan dapat diaudit.

3. `Documentation: add README and data dictionary`  
   Berisi dokumentasi repository dan penjelasan variabel.

4. `Add model output and interpretability visualizations`  
   Berisi hasil output pipeline berupa CSV dan visualisasi PNG.

## Interpretabilitas Model

Model XGBoost tidak hanya menghasilkan prediksi, tetapi juga dilengkapi dengan interpretabilitas. Pada level global, feature importance digunakan untuk melihat fitur yang paling berpengaruh pada model secara umum.

Selain itu, pipeline juga menggunakan `predcontrib = TRUE` untuk melihat kontribusi fitur pada prediksi pasien tertentu. Output ini membantu menjelaskan mengapa model memberi skor risiko tertentu pada pasien, sehingga hasil model dapat lebih mudah dipahami oleh klinisi.

## Catatan Klinis

Hasil model pada project ini tidak digunakan untuk keputusan klinis nyata karena dataset yang digunakan adalah data dummy. Model ini hanya digunakan untuk tujuan pembelajaran mengenai reproducibility, auditability, privacy, dan interpretabilitas dalam analisis Big Data kesehatan.

Dalam konteks data EHR asli, hasil prediksi model perlu divalidasi secara klinis, terutama pada kasus false negative, potensi data leakage, bias pada ground truth, serta kemungkinan kesalahan input data medis.

## Privasi Data

Karena dataset yang digunakan merupakan data dummy, data dapat dibagikan untuk kebutuhan pembelajaran. Namun, jika pipeline ini diterapkan pada data EHR nyata, direct identifier seperti nama pasien, nomor rekam medis, alamat, dan nomor kontak harus dihapus.

Data sensitif sebaiknya tidak dibagikan secara bebas. Kode dan dokumentasi dapat dibagikan secara terbuka, sedangkan data pasien asli perlu menggunakan mekanisme akses terbatas atau controlled access.

## Kesimpulan

Repository ini menunjukkan proses perbaikan pipeline analisis data kesehatan dari kode awal yang kurang rapi menjadi kode yang lebih terstruktur, auditable, dan interpretable. Dengan dokumentasi README, data dictionary, output CSV, visualisasi, serta riwayat commit Git, project ini diharapkan dapat mendukung prinsip reproducibility dan FAIR dalam analisis Big Data kesehatan.
