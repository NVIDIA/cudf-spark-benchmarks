
WITH CustomerSaleSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_id
),
FinalSummary AS (
    SELECT 
        css.c_customer_id,
        css.cd_gender,
        css.cd_marital_status,
        ws.w_warehouse_id,
        ws.total_profit,
        ws.total_orders,
        css.total_sales,
        css.total_orders AS customer_orders
    FROM 
        CustomerSaleSummary css
    JOIN 
        WarehouseSummary ws ON css.total_orders > 5
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    f.w_warehouse_id,
    f.total_profit,
    f.total_orders,
    f.total_sales,
    f.customer_orders
FROM 
    FinalSummary f
ORDER BY 
    f.total_sales DESC
LIMIT 100;
