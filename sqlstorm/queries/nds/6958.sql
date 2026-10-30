
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cs.cs_quantity) AS total_quantity_purchased,
        SUM(cs.cs_ext_sales_price) AS total_sales_volume,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ds.d_date AS sale_date,
    ss.total_orders,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_profit,
    cs.total_customers,
    cs.total_quantity_purchased,
    cs.total_sales_volume,
    cs.total_profit
FROM 
    sales_summary ss
JOIN 
    date_dim ds ON ss.ws_sold_date_sk = ds.d_date_sk
LEFT JOIN 
    customer_summary cs ON cs.cd_gender IS NOT NULL
ORDER BY 
    sale_date;
