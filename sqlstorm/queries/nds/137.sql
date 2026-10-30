
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        ct.total_web_sales
    FROM CustomerStats ct
    JOIN customer c ON ct.c_customer_sk = c.c_customer_sk
    WHERE ct.total_web_sales > (
        SELECT AVG(total_web_sales)
        FROM CustomerStats
    )
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
    cs.cd_gender,
    cs.total_web_sales,
    cs.total_web_orders,
    hs.total_web_sales AS high_spender_sales,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    COALESCE(rs.total_return_count, 0) AS total_return_count,
    wss.total_profit,
    wss.order_count,
    wss.avg_order_value
FROM CustomerStats cs
LEFT JOIN HighSpenders hs ON cs.c_customer_sk = hs.customer_id
LEFT JOIN ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
LEFT JOIN WebSalesSummary wss ON cs.c_customer_sk = wss.ws_bill_customer_sk
WHERE cs.rank <= 10
ORDER BY cs.total_web_sales DESC;
