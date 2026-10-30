
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        COUNT(DISTINCT sr_ticket_number) AS return_count, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit, 
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.return_count,
    cs.total_return_amt,
    ss.total_profit,
    ss.total_quantity
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesStats ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cs.return_count > 5 AND ss.total_profit IS NOT NULL
ORDER BY 
    cs.total_return_amt DESC, ss.total_profit DESC
LIMIT 100;
