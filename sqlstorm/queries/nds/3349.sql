
WITH sales_summary AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sales_date,
        s.s_store_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0)) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store s ON s.s_store_sk = ws.ws_ship_addr_sk OR s.s_store_sk = cs.cs_ship_addr_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date, s.s_store_name
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_marital_status) AS marital_status,
        MAX(cd.cd_gender) AS gender,
        COUNT(DISTINCT hd.hd_income_band_sk) AS unique_income_bands
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
return_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    ss.sales_date,
    ss.s_store_name,
    ss.total_quantity,
    ss.total_sales_amount,
    cs.marital_status,
    cs.gender,
    cs.unique_income_bands,
    COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN ss.total_sales_amount = 0 THEN NULL 
        ELSE ROUND((COALESCE(rs.total_return_amount, 0) / ss.total_sales_amount) * 100, 2)
    END AS return_percentage
FROM sales_summary ss
LEFT JOIN customer_summary cs ON cs.c_customer_sk IN (
    SELECT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_first_name LIKE 'A%'
)
LEFT JOIN return_summary rs ON rs.cr_item_sk IN (
    SELECT ws.ws_item_sk 
    FROM web_sales ws 
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
)
WHERE ss.total_quantity > 0
ORDER BY ss.sales_date, ss.s_store_name;
