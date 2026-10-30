
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
qualified_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ss.total_quantity,
        ss.total_profit,
        COALESCE(rs.total_returned, 0) AS total_returned,
        rs.total_return_amount
    FROM customer_data cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON cd.c_customer_sk = rs.sr_customer_sk
    WHERE cd.cd_purchase_estimate > (
        SELECT AVG(cd2.cd_purchase_estimate) 
        FROM customer_demographics cd2 
        WHERE cd2.cd_credit_rating = 'Excellent'
    )
      AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.total_quantity,
    c.total_profit,
    c.total_returned,
    c.total_return_amount,
    CASE 
        WHEN c.total_profit IS NULL THEN 'No Profit'
        WHEN c.total_profit < 0 THEN 'Loss'
        WHEN c.total_profit / NULLIF(c.total_quantity, 0) < 5 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY c.total_profit >= 0 ORDER BY c.total_profit DESC) AS profit_rank
FROM qualified_customers c
WHERE NOT EXISTS (
    SELECT 1 FROM store s 
    WHERE s.s_manager = c.c_last_name 
      AND s.s_state IS NOT NULL
)
ORDER BY c.total_profit DESC, c.total_quantity DESC;
