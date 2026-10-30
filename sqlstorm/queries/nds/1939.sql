
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2415 AND 2420  
    GROUP BY 
        ss_store_sk, ss_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_purchase_estimate > 500
),
store_address AS (
    SELECT 
        s.s_store_sk,
        CONCAT(s.s_street_number, ' ', s.s_street_name, ' ', s.s_city, ', ', s.s_state) AS full_address
    FROM 
        store s
)
SELECT 
    sa.full_address,
    COUNT(DISTINCT ci.c_customer_sk) AS female_customers,
    SUM(rs.total_sales) AS total_sales_by_store,
    COALESCE(MAX(rs.total_sales), 0) AS max_sales,
    CASE 
        WHEN MAX(rs.total_sales) IS NOT NULL AND MIN(rs.total_sales) IS NOT NULL 
        THEN (MAX(rs.total_sales) - MIN(rs.total_sales)) * 1.0 / NULLIF(MIN(rs.total_sales), 0)
        ELSE NULL 
    END AS sales_growth_rate
FROM 
    ranked_sales rs
JOIN 
    store_address sa ON rs.ss_store_sk = sa.s_store_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk IN (
        SELECT DISTINCT 
            ws_bill_customer_sk
        FROM 
            web_sales
        WHERE 
            ws_sold_date_sk BETWEEN 2415 AND 2420
    )
GROUP BY 
    sa.full_address
ORDER BY 
    total_sales_by_store DESC
LIMIT 10;
