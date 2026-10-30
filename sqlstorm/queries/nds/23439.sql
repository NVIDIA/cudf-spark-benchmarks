
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (
            SELECT AVG(ws2.ws_sales_price) 
            FROM web_sales ws2 
            WHERE ws2.ws_item_sk = ws.ws_item_sk
        )
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseShippingCosts AS (
    SELECT 
        w.w_warehouse_sk, 
        SUM(COALESCE(ws.ws_ext_ship_cost, 0)) AS total_ship_cost
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_status,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
    wsc.total_ship_cost
FROM 
    RankedSales rs
JOIN 
    CustomerInfo ci ON rs.ws_item_sk = ci.c_customer_sk
JOIN 
    WarehouseShippingCosts wsc ON rs.ws_order_number = wsc.w_warehouse_sk
WHERE 
    rs.sales_rank = 1
    AND wsc.total_ship_cost IS NOT NULL
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.marital_status,
    wsc.total_ship_cost
HAVING 
    SUM(rs.ws_sales_price * rs.ws_quantity) > 1000
ORDER BY 
    total_sales_value DESC NULLS LAST
