
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    INNER JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_name
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    INNER JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.ws_sold_date_sk,
    ss.w_warehouse_name,
    ss.total_sales,
    ss.total_discount,
    cs.cd_gender,
    cs.customer_count,
    cs.total_profit
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON ss.ws_sold_date_sk = cs.customer_count
ORDER BY 
    ss.ws_sold_date_sk, ss.total_sales DESC;
