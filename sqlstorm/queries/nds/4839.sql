
WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
web_sales_data AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cr.total_store_returns, 0) AS total_store_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ws.total_web_profit, 0) AS total_web_profit,
        COALESCE(ws.total_web_orders, 0) AS total_web_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.c_customer_sk
    LEFT JOIN web_sales_data ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_store_returns,
    cs.total_returned_amount,
    cs.total_web_profit,
    cs.total_web_orders,
    RANK() OVER (ORDER BY cs.total_web_profit DESC) AS profit_rank,
    CASE 
        WHEN cs.total_store_returns > 0 THEN 'Active Returner'
        ELSE 'Non-Returner'
    END AS return_status
FROM customer_summary cs
WHERE (cs.total_web_orders > 5 OR cs.total_store_returns > 0)
AND cs.cd_gender = 'F'
ORDER BY cs.total_web_profit DESC;
