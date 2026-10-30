
WITH CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
OddlyFrequentPurchase AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 10  
        AND AVG(ws.ws_sales_price) > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_sales_price IS NOT NULL)
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
FinalStats AS (
    SELECT 
        cps.c_first_name,
        cps.c_last_name,
        cps.total_spent,
        cps.order_count,
        COALESCE(ofp.distinct_orders, 0) AS frequent_orders,
        wi.total_quantity,
        wi.distinct_items
    FROM 
        CustomerPurchaseStats cps
    LEFT JOIN 
        OddlyFrequentPurchase ofp ON cps.c_customer_sk = ofp.c_customer_sk
    JOIN 
        WarehouseInventory wi ON 1=1
    WHERE 
        cps.rank_by_gender = 1
        AND cps.total_spent IS NOT NULL
)
SELECT 
    fs.c_first_name,
    fs.c_last_name,
    fs.total_spent,
    fs.order_count,
    fs.frequent_orders,
    fs.total_quantity,
    fs.distinct_items,
    CASE 
        WHEN fs.frequent_orders > 0 THEN 'Frequent Buyer' 
        ELSE 'Casual Buyer' 
    END AS buyer_category
FROM 
    FinalStats fs
ORDER BY 
    fs.total_spent DESC
LIMIT 100;
