
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
DailySales AS (
    SELECT 
        d.d_date AS sale_date, 
        SUM(s.total_sales) AS daily_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num
    FROM date_dim d
    LEFT JOIN SalesCTE s ON d.d_date_sk = s.ws_sold_date_sk
    GROUP BY d.d_date
)
SELECT 
    ds.sale_date,
    CASE 
        WHEN ds.daily_sales IS NULL THEN 'No Sales'
        ELSE CAST(ds.daily_sales AS STRING)
    END AS sales_amount,
    LAG(ds.daily_sales) OVER (ORDER BY ds.sale_date) AS previous_day_sales,
    CASE 
        WHEN ds.daily_sales > COALESCE(LAG(ds.daily_sales) OVER (ORDER BY ds.sale_date), 0) THEN 'Increased'
        WHEN ds.daily_sales < COALESCE(LAG(ds.daily_sales) OVER (ORDER BY ds.sale_date), 0) THEN 'Decreased'
        ELSE 'No Change'
    END AS sales_trend
FROM DailySales ds
WHERE ds.row_num <= 30
ORDER BY ds.sale_date DESC;
