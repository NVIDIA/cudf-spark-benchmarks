
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2457208 AND 2457283  
    GROUP BY 
        ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cu.total_sales,
        cu.total_orders,
        cu.avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary cu ON c.c_customer_sk = cu.ws_bill_customer_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws_ext_sales_price) AS total_warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws_sold_date_sk BETWEEN 2457208 AND 2457283 
    GROUP BY 
        w.w_warehouse_id
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        ws.total_warehouse_sales,
        cs.total_sales,
        cs.total_orders,
        cs.avg_net_profit
    FROM 
        customer_summary cs
    JOIN 
        warehouse_summary ws ON cs.total_sales > 1000  
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.total_warehouse_sales,
    f.total_sales,
    f.total_orders,
    f.avg_net_profit
FROM 
    final_summary f
ORDER BY 
    f.total_sales DESC
LIMIT 50;
