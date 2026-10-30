
WITH  CustomerReturns AS (
    SELECT sr_cdemo_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY sr_cdemo_sk
),
RevenueSummary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        COUNT(DISTINCT ws_order_number) AS total_web_orders
    FROM customer c 
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        AVG(rs.total_spent) AS avg_spent,
        AVG(COALESCE(cr.total_returns, 0)) AS avg_returns
    FROM RevenueSummary rs
    JOIN customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.sr_cdemo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    d.cd_gender,
    d.avg_spent,
    d.avg_returns,
    CASE 
        WHEN d.avg_spent > 1000 THEN 'High Value'
        WHEN d.avg_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM DemographicAnalysis d
WHERE d.avg_returns IS NOT NULL
ORDER BY d.avg_spent DESC;
