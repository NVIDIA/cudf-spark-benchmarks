
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023
        )
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rn
    FROM 
        SalesData sd
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    COALESCE((
        SELECT AVG(hi.hd_income_band_sk) 
        FROM household_demographics hi
        WHERE hi.hd_demo_sk IN (
            SELECT c.c_current_hdemo_sk 
            FROM customer c
            WHERE c.c_customer_sk IN (
                SELECT sr.sr_customer_sk
                FROM store_returns sr
                WHERE sr.sr_return_quantity > 0
            )
        )
    ), 0) AS average_income_band,
    CASE 
        WHEN ti.total_sales > 10000 THEN 'High Performer'
        WHEN ti.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    TopItems ti
WHERE 
    ti.rn <= 10
ORDER BY 
    ti.total_sales DESC;
