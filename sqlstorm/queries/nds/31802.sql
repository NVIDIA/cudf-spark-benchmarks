
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
store_data AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_paid) AS total_store_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
combined_results AS (
    SELECT 
        a.ca_city,
        COALESCE(sds.total_store_quantity, 0) AS total_store_quantity,
        COALESCE(sds.total_store_sales, 0) AS total_store_sales,
        SUM(ss.total_quantity) AS total_web_quantity,
        SUM(ss.total_sales) AS total_web_sales
    FROM 
        customer_address AS a
    LEFT JOIN 
        sales_summary AS ss ON ss.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq = 6
        )
    LEFT JOIN 
        store_data AS sds ON a.ca_address_sk = sds.ss_store_sk
    GROUP BY 
        a.ca_city, sds.total_store_quantity, sds.total_store_sales
)
SELECT 
    city_summary.ca_city,
    city_summary.total_store_quantity,
    city_summary.total_store_sales,
    city_summary.total_web_quantity,
    city_summary.total_web_sales,
    CASE 
        WHEN city_summary.total_web_quantity > 0 THEN 
            city_summary.total_web_sales / city_summary.total_web_quantity 
        ELSE NULL 
    END AS avg_web_sales_per_item,
    CASE 
        WHEN city_summary.total_store_quantity > 0 THEN 
            city_summary.total_store_sales / city_summary.total_store_quantity 
        ELSE NULL 
    END AS avg_store_sales_per_item
FROM 
    combined_results AS city_summary
WHERE 
    city_summary.total_web_sales > 0 OR city_summary.total_store_sales > 0
ORDER BY 
    city_summary.total_web_sales DESC, city_summary.total_store_sales DESC
LIMIT 100;
