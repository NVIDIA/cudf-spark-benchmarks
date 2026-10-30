
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
BestCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_net_profit
    FROM 
        CustomerStats cs
    WHERE 
        cs.gender_rank <= 5
),
ReturnsStats AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    bc.c_customer_sk,
    bc.c_first_name,
    bc.c_last_name,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    (CASE 
        WHEN rs.total_returns IS NOT NULL THEN 'Has Returns' 
        ELSE 'No Returns' 
    END) AS return_status,
    (bc.total_net_profit - COALESCE(rs.total_return_amt, 0)) AS net_profit_after_returns
FROM 
    BestCustomers bc
LEFT JOIN 
    ReturnsStats rs ON bc.c_customer_sk = rs.sr_customer_sk
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
