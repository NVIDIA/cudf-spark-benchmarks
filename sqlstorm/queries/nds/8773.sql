
SELECT 
    c.c_customer_id,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq
HAVING 
    SUM(ws.ws_net_profit) > 1000 
ORDER BY 
    total_profit DESC
LIMIT 100;
