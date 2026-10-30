
WITH sales_data AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS warehouse_total_quantity,
        SUM(ws.ws_ext_sales_price) AS warehouse_total_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit,
    ws.warehouse_total_quantity,
    ws.warehouse_total_sales
FROM 
    sales_data sd
JOIN 
    customer_data cu ON cu.c_customer_sk = sd.cs_item_sk
JOIN 
    warehouse_sales ws ON ws.warehouse_total_quantity > 1000
WHERE 
    cu.cd_credit_rating = 'Good'
    AND cu.cd_purchase_estimate > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
