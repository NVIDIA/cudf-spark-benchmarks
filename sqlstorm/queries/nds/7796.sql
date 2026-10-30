
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
ReturnSummary AS (
    SELECT 
        sr.sr_customer_sk, 
        COUNT(sr.sr_ticket_number) AS total_returns, 
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender, 
    cs.cd_marital_status, 
    cs.cd_education_status, 
    cs.total_spent, 
    cs.total_orders, 
    rs.total_returns, 
    rs.total_returned 
FROM 
    CustomerSummary cs
LEFT JOIN 
    ReturnSummary rs ON cs.c_customer_sk = rs.sr_customer_sk
WHERE 
    cs.total_spent > 1000 
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
