
WITH sales_summary AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2022 AND cd.cd_gender = 'F'
    GROUP BY 
        CAST(d.d_date AS DATE)
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        customer_profit DESC
    LIMIT 10
)
SELECT 
    ss.sale_date,
    ss.total_profit,
    ss.total_quantity,
    ss.order_count,
    (SELECT COUNT(*) FROM top_customers) AS top_customers_count
FROM 
    sales_summary ss
ORDER BY 
    ss.sale_date;
