
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
return_stats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
final_stats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.total_quantity,
        cs.total_orders,
        cs.avg_sales_price,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        (CASE 
            WHEN cs.total_orders > 0 THEN ROUND((COALESCE(rs.total_return_amount, 0) / NULLIF(cs.total_orders, 0)), 2)
            ELSE 0 
        END) AS return_rate
    FROM customer_stats cs
    LEFT JOIN return_stats rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name || ' ' || f.c_last_name AS full_name,
    f.cd_gender,
    f.cd_marital_status,
    f.total_quantity,
    f.total_orders,
    f.avg_sales_price,
    f.total_returns,
    f.total_return_amount,
    f.return_rate
FROM final_stats f
WHERE (f.return_rate > 0.1 OR (f.cd_marital_status = 'M' AND f.total_orders > 5))
ORDER BY f.return_rate DESC, f.avg_sales_price ASC
LIMIT 100;
