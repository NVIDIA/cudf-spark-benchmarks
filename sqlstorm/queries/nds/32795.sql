
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sales_price > 0
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM catalog_sales
    WHERE cs_sales_price > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales,
        COUNT(DISTINCT s.ws_order_number) AS order_count,
        AVG(s.ws_sales_price) AS avg_sales_price
    FROM sales_cte s
    GROUP BY s.ws_item_sk
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
),
final_summary AS (
    SELECT 
        cu.c_first_name,
        cu.c_last_name,
        ss.total_sales,
        ss.order_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count
    FROM customer_info cu
    LEFT JOIN sales_summary ss ON cu.c_customer_sk = ss.ws_item_sk
    LEFT JOIN returns_summary rs ON ss.ws_item_sk = rs.sr_item_sk
    WHERE ss.total_sales > 1000
)
SELECT 
    *,
    CASE 
        WHEN total_sales > total_returns * 10 THEN 'Highly Profitable'
        WHEN total_sales > total_returns THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM final_summary
ORDER BY total_sales DESC
LIMIT 10;
