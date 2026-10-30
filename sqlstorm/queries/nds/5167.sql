
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
), 
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_net_profit) AS demographic_net_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.unique_customers = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.demographic_net_profit, 
    SUM(ss.total_orders) AS total_orders
FROM 
    customer_demographics cd
JOIN 
    sales_summary ss ON cd.demographic_net_profit > 0
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.demographic_net_profit
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;
