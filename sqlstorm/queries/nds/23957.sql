
WITH seasonal_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 12
        )
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk
),
top_web_sites AS (
    SELECT 
        ws_web_site_sk,
        SUM(total_sales) AS total_site_sales
    FROM 
        seasonal_sales
    WHERE 
        rank <= 5
    GROUP BY 
        ws_web_site_sk
),
order_stats AS (
    SELECT 
        ss_store_sk,
        COALESCE(SUM(ss_ext_sales_price), 0) AS store_total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
sales_data AS (
    SELECT 
        wb.web_site_id,
        wb.web_name,
        COALESCE(ts.total_site_sales, 0) AS total_sales,
        os.store_total_sales,
        os.total_orders
    FROM 
        web_site wb
    LEFT JOIN top_web_sites ts ON wb.web_site_sk = ts.ws_web_site_sk
    LEFT JOIN order_stats os ON os.ss_store_sk = (
        SELECT s_store_sk 
        FROM store 
        WHERE s_state = 'CA' 
        ORDER BY s_number_employees DESC 
        LIMIT 1
    )
)
SELECT 
    w.web_site_id,
    w.web_name,
    w.total_sales,
    w.store_total_sales,
    w.total_orders,
    CASE 
        WHEN w.total_sales > 0 THEN ROUND((w.store_total_sales / w.total_sales) * 100, 2)
        ELSE NULL
    END AS sales_percentage,
    (SELECT COUNT(DISTINCT c_customer_id)
     FROM customer c
     WHERE c.c_current_addr_sk IS NOT NULL) AS unique_customers,
    (SELECT COUNT(*)
     FROM item i
     WHERE i.i_current_price > (
         SELECT COALESCE(AVG(i2.i_current_price), 0) 
         FROM item i2 
         WHERE i2.i_rec_end_date IS NULL
     )
    ) AS expensive_items
FROM 
    sales_data w
WHERE 
    w.total_orders > (SELECT AVG(total_orders) FROM order_stats)
ORDER BY 
    w.total_sales DESC;
