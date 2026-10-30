
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn,
        CASE 
            WHEN ws_ext_sales_price IS NULL THEN 0
            ELSE ws_ext_sales_price
        END AS safe_sales_price
    FROM web_sales
    WHERE ws_sales_price > 0
),
top_sales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        SUM(rs.safe_sales_price) AS total_sales,
        COUNT(*) OVER (PARTITION BY rs.ws_item_sk) AS sales_count
    FROM ranked_sales rs
    WHERE rs.rn <= 5
    GROUP BY rs.ws_item_sk, rs.ws_order_number
),
cust_info AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        d.d_year,
        cd.cd_gender
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
),
result AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_gender,
        SUM(ts.total_sales) AS total_customer_sales,
        AVG(ts.total_sales) AS avg_order_value,
        CASE 
            WHEN SUM(ts.total_sales) > 1000 THEN 'High Roller'
            WHEN SUM(ts.total_sales) BETWEEN 500 AND 1000 THEN 'Moderate'
            ELSE 'Low Spender'
        END AS customer_spending_category
    FROM cust_info ci
    LEFT JOIN top_sales ts ON ci.c_customer_sk = ts.ws_order_number
    GROUP BY ci.c_customer_sk, ci.cd_gender
)
SELECT 
    rc.c_customer_sk,
    rc.cd_gender,
    rc.total_customer_sales,
    rc.avg_order_value,
    rc.customer_spending_category,
    RANK() OVER (ORDER BY rc.total_customer_sales DESC) AS sales_rank,
    CASE 
        WHEN rc.avg_order_value IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM result rc
WHERE rc.total_customer_sales IS NOT NULL
ORDER BY rc.total_customer_sales DESC;
