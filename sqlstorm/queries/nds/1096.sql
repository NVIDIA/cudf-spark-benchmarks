
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_order_number, ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sd.total_sales) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_order_number
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_ship_cost) AS average_ship_cost
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    wa.w_warehouse_id,
    wa.total_net_profit,
    wa.average_ship_cost,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.gender_rank
FROM 
    WarehouseSales wa
JOIN 
    CustomerData cd ON cd.gender_rank = 1
WHERE 
    wa.total_net_profit IS NOT NULL
ORDER BY 
    wa.total_net_profit DESC, 
    cd.cd_gender;
