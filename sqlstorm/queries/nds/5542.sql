
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id AS customer_id,
        total_net_profit,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 10
),
sales_per_month AS (
    SELECT 
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        dd.d_month_seq
)
SELECT 
    tc.customer_id,
    tc.total_net_profit,
    tc.total_orders,
    pm.d_month_seq,
    pm.total_sales
FROM 
    top_customers tc
JOIN 
    sales_per_month pm ON pm.total_sales > 10000
ORDER BY 
    tc.total_net_profit DESC, 
    pm.total_sales DESC;
