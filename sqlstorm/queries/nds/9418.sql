
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        c.c_birth_year,
        cd.cd_gender
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_order_number, d.d_year, c.c_birth_year, cd.cd_gender
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_sales) AS avg_sales,
        AVG(total_discount) AS avg_discount,
        AVG(total_profit) AS avg_profit
    FROM 
        sales_data
    JOIN 
        customer c ON sales_data.ws_order_number = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cs.cd_gender,
    cs.order_count,
    cs.avg_quantity,
    cs.avg_sales,
    cs.avg_discount,
    cs.avg_profit,
    CASE 
        WHEN cs.avg_profit > 1000 THEN 'High Performer'
        WHEN cs.avg_profit BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    customer_summary cs
ORDER BY 
    cs.avg_profit DESC;
