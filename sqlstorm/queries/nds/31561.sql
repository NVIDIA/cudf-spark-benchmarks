
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2020) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS customer_total_quantity
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ShippingInfo AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(*) AS total_shipments,
        AVG(ws.ws_net_paid) AS avg_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.customer_total_quantity,
    ss.total_quantity AS store_total_quantity,
    ss.total_sales AS store_total_sales,
    si.total_shipments,
    si.avg_shipping_cost,
    COALESCE(s.rn, 0) AS recursive_rank
FROM 
    CustomerSales cs
JOIN 
    TotalSales ss ON cs.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    SalesCTE s ON cs.customer_total_quantity = s.ws_quantity
JOIN 
    ShippingInfo si ON si.total_shipments > 0
WHERE 
    cs.customer_total_quantity > (
        SELECT AVG(customer_total_quantity)
        FROM CustomerSales
    )
ORDER BY 
    cs.customer_total_quantity DESC
LIMIT 50;
