
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
    HAVING 
        SUM(cs_quantity) > 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status,
        cd.cd_gender, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
InventoryAnalysis AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        MAX(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 1 ELSE 0 END) AS has_null 
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name,
    s.total_sales, 
    s.total_profit,
    i.total_inventory, 
    i.has_null,
    CASE 
        WHEN c.cd_gender = 'M' THEN 'Male'
        WHEN c.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc
FROM 
    CustomerInfo c
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    InventoryAnalysis i ON s.ws_item_sk = i.inv_item_sk
WHERE 
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_item_sk = s.ws_item_sk
        AND ss.ss_net_profit > 0
    )
OR EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = s.ws_item_sk
        AND sr.sr_return_quantity > 5
    )
ORDER BY 
    total_profit DESC, c.c_last_name ASC;
