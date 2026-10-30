
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10001
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.avg_net_profit,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_summary cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.avg_net_profit,
    rt.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
FROM 
    top_customers tc
LEFT JOIN 
    store_returns sr ON tc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason rt ON sr.sr_reason_sk = rt.r_reason_sk
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, 
    tc.total_sales, tc.total_orders, tc.avg_net_profit, rt.r_reason_desc
ORDER BY 
    total_sales DESC;
