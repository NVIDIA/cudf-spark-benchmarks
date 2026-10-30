
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451504 AND 2451533 
    GROUP BY 
        ws_item_sk, ws_ship_mode_sk
), 
recent_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        RANK() OVER (ORDER BY c_first_shipto_date_sk DESC) AS recent_rank
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL AND 
        (c_birth_month * c_birth_day) % 2 = 0
), 
sales_summary AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rc.c_first_name,
        rc.c_last_name,
        (rc.c_birth_year - EXTRACT(YEAR FROM DATE '2002-10-01')) AS age
    FROM 
        ranked_sales rs 
    LEFT JOIN 
        recent_customers rc ON rs.ws_item_sk = rc.c_customer_sk
    WHERE 
        rs.sales_rank <= 10
), 
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS overall_sales 
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_sales,
    ss.c_first_name,
    ss.c_last_name,
    ts.overall_sales,
    CASE 
        WHEN ss.total_sales > 10000 THEN 'High Volume'
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 'Low Volume'
    END AS sales_category,
    COALESCE(ss.age, 0) AS customer_age,
    REPLACE(COALESCE(ss.c_first_name, ''), '.', '') AS clean_name
FROM 
    sales_summary ss
FULL OUTER JOIN 
    total_sales ts ON ss.ws_item_sk = ts.ws_item_sk
WHERE 
    ss.total_sales IS NOT NULL OR 
    (ss.total_sales IS NULL AND ts.overall_sales > 5000)
ORDER BY 
    customer_age DESC, 
    sales_category, 
    ss.total_sales DESC;
