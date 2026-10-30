
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2002-10-01')
),
filtered_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(sd.ws_order_number) AS order_count
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 5 
    GROUP BY 
        sd.ws_item_sk
),
biggest_sales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
    FROM 
        filtered_sales
),
income_band_sales AS (
    SELECT 
        ib.ib_income_band_sk AS income_band,
        SUM(CASE WHEN c.c_current_cdemo_sk IS NOT NULL THEN fs.total_sales ELSE 0 END) AS income_sales
    FROM 
        income_band ib
    LEFT JOIN 
        household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        filtered_sales fs ON c.c_customer_sk = fs.ws_item_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    b.ws_item_sk,
    b.total_sales,
    COALESCE(SUM(ibs.income_sales), 0) AS total_income_sales
FROM 
    biggest_sales b
LEFT JOIN 
    income_band_sales ibs ON b.ws_item_sk = ibs.income_band
WHERE 
    b.row_num <= 10 OR (b.row_num > 10 AND b.total_sales > (SELECT MAX(total_sales) FROM biggest_sales) * 0.1)
GROUP BY 
    b.ws_item_sk, 
    b.total_sales
HAVING 
    (CASE 
        WHEN COALESCE(SUM(ibs.income_sales), 0) > 0 THEN b.total_sales / COALESCE(SUM(ibs.income_sales), 0)
        ELSE NULL
    END) > 1.5
ORDER BY 
    b.total_sales DESC;
