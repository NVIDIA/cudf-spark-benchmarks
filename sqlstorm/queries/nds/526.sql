
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        DENSE_RANK() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spending
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    AVG(cs.total_spending) AS avg_customer_spending,
    COUNT(DISTINCT rs.ws_item_sk) AS unique_items_sold,
    SUM(COALESCE(ir.total_quantity, 0)) AS total_inventory,
    SUM(COALESCE(sr.total_returns, 0)) AS total_returns
FROM 
    customer_address ca
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = cs.c_customer_sk
LEFT JOIN 
    InventoryCheck ir ON ir.inv_item_sk = rs.ws_item_sk
LEFT JOIN 
    SalesReturns sr ON sr.sr_item_sk = ir.inv_item_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND cs.total_orders > 10
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    AVG(cs.total_spending) > 100
ORDER BY 
    avg_customer_spending DESC;
