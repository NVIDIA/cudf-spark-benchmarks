WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
), 
RecentReturns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    COALESCE(rr.total_returns, 0) AS total_returns,
    cs.total_net_profit,
    cs.total_orders,
    cs.gender_rank
FROM 
    CustomerStats cs
LEFT JOIN 
    RecentReturns rr ON cs.c_customer_sk = rr.sr_customer_sk
WHERE 
    (cs.total_net_profit > 1000 OR cs.total_orders > 5)
    AND cs.gender_rank <= 10
ORDER BY 
    cs.total_net_profit DESC
LIMIT 50;