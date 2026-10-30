
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_quantity > 0
), 
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        sr_customer_sk
), 
InventoryDetails AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
), 
PurchaseCounts AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_purchases
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(s.ws_net_paid), 0) AS total_spent,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(p.total_purchases, 0) AS total_purchases,
    COALESCE(i.total_inventory, 0) AS total_inventory_on_hand
FROM 
    customer c
LEFT JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    PurchaseCounts p ON c.c_customer_sk = p.c_customer_sk
LEFT JOIN 
    InventoryDetails i ON s.ws_item_sk = i.inv_item_sk
WHERE 
    c.c_birth_year IS NOT NULL AND
    (c.c_birth_month BETWEEN 1 AND 12 OR c.c_birth_day BETWEEN 1 AND 31)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, r.total_returns, p.total_purchases, i.total_inventory
HAVING 
    SUM(s.ws_net_paid) > 1000 OR 
    COALESCE(r.total_returns, 0) > 0
ORDER BY 
    total_spent DESC;
