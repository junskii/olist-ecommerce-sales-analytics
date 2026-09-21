# E-Commerce Sales Analytics — Olist

## Ringkasan

Project ini menganalisis performa penjualan e-commerce menggunakan [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Tujuannya adalah memahami tren transaksi, kontribusi kategori produk dan wilayah customer, pembelian ulang, serta hubungan antara keterlambatan pengiriman dan review pelanggan.

Data diolah menggunakan **MySQL** dan divisualisasikan dengan **Tableau Public**.

## Pertanyaan bisnis

1. Bagaimana tren GMV dan jumlah order dari bulan ke bulan?
2. Kategori produk dan wilayah customer mana yang menyumbang GMV terbesar?
3. Berapa banyak customer yang membeli lebih dari sekali?
4. Apakah order yang terlambat memiliki review score lebih rendah?

## Definisi metrik

Analisis penjualan menggunakan order berstatus `delivered`.

- **GMV:** jumlah harga produk dan ongkir (`price + freight_value`).
- **AOV:** GMV dibagi jumlah order unik.
- **Repeat customer:** customer dengan lebih dari satu order `delivered`, dikenali melalui `customer_unique_id`.
- **Late delivery:** tanggal diterima customer melewati tanggal estimasi pengiriman.

GMV menunjukkan nilai transaksi menurut definisi project ini, bukan laba atau pendapatan bersih Olist.

## Temuan utama

- **96.478** order `delivered` menghasilkan GMV **15.419.773,75**, dengan AOV **159,83**.
- November 2017 memiliki GMV bulanan tertinggi, yaitu **1.153.364,20** dari **7.289** order.
- `health_beauty` adalah kategori dengan GMV tertinggi (**1.412.089,53**).
- State **SP** menyumbang GMV terbesar (**5.769.703,15**).
- **2.801 dari 93.358 customer** membeli lebih dari sekali, atau **3,00%**.
- Rata-rata review score order terlambat adalah **2,57**, dibandingkan **4,29** untuk order tepat waktu. Hubungan ini tidak membuktikan sebab-akibat.

Pembahasan dan rekomendasi selengkapnya ada di `insights/business_recommendations.md`.

## Isi project

- `sql/01_setup_and_import.sql` — struktur tabel dan proses impor CSV.
- `sql/02_data_quality_checks.sql` — pemeriksaan jumlah baris, nilai kosong, dan relasi data.
- `sql/03_exploration.sql` — eksplorasi dan KPI dasar.
- `sql/04_business_analysis.sql` — query untuk menjawab pertanyaan bisnis.
- `sql/05_tableau_export.sql` — query pembentuk dua dataset dashboard.
- `dashboard_data/` — CSV level order dan level item untuk Tableau.
- `dashboard/` — workbook Tableau.
- `insights/business_recommendations.md` — interpretasi hasil dan rekomendasi.

## Batasan analisis

Dataset tidak menyediakan informasi lengkap tentang biaya operasional, laba, promosi, atau penyebab pasti review buruk. Sebagian order juga tidak memiliki tanggal pengiriman atau review. Karena itu, rekomendasi disusun sebagai arah investigasi dan perbaikan, bukan kesimpulan sebab-akibat.