
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
Inventory_Stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv 
    GROUP BY 
        inv.inv_item_sk
),
Customer_Info AS (
    SELECT 
        ca.ca_address_sk,
        cd.cd_demo_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', c.c_first_name)
            ELSE CONCAT('Ms. ', c.c_first_name)
        END AS full_name,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown' 
            ELSE cd.cd_marital_status 
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.marital_status,
    iv.total_quantity_on_hand,
    COALESCE(sc.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sc.total_sales, 0) AS total_sales
FROM 
    Customer_Info ci
LEFT JOIN 
    Inventory_Stats iv ON ci.ca_address_sk = iv.inv_item_sk
LEFT JOIN 
    Sales_CTE sc ON iv.inv_item_sk = sc.ws_item_sk
WHERE 
    (ci.marital_status = 'M' OR ci.marital_status = 'S') 
    AND (iv.total_quantity_on_hand IS NOT NULL OR COALESCE(sc.total_quantity, 0) > 0)
ORDER BY 
    total_sales DESC
LIMIT 50;
