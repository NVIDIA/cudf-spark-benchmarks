
WITH sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        sales.ws_bill_customer_sk,
        sales.total_quantity,
        sales.total_sales,
        sales.total_profit,
        sales.total_orders,
        RANK() OVER (ORDER BY sales.total_profit DESC) AS profit_rank
    FROM 
        sales_summary sales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_quantity,
    tc.total_sales,
    tc.total_profit,
    tc.total_orders
FROM 
    top_customers tc
JOIN 
    customer c ON tc.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;
