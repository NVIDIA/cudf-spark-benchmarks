
WITH  Sales_Hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
Top_Sellers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_profit,
        sh.cd_gender,
        CASE 
            WHEN sh.sales_rank <= 10 THEN 'Top Seller'
            ELSE 'Regular Seller'
        END AS seller_type
    FROM 
        Sales_Hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    WHERE 
        sh.sales_rank <= 10 OR sh.total_profit > 1000
),
Inventory_Summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.total_profit,
    ts.seller_type,
    item.i_item_desc,
    inv.total_quantity,
    inv.avg_quantity,
    COALESCE(band.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(band.ib_upper_bound, 0) AS income_upper_bound
FROM 
    Top_Sellers ts
JOIN 
    web_sales ws ON ts.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item ON ws.ws_item_sk = item.i_item_sk
LEFT JOIN 
    inventory_summary inv ON item.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk = ts.c_customer_sk
LEFT JOIN 
    income_band band ON hd.hd_income_band_sk = band.ib_income_band_sk
WHERE 
    ts.total_profit > 1000 OR inv.total_quantity > 50
ORDER BY 
    ts.total_profit DESC, ts.c_first_name ASC;
