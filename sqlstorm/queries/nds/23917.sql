
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        (ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    AND 
        c.c_preferred_cust_flag = 'Y'
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity,
        rs.net_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_order_number,
        ts.net_price,
        COALESCE(ic.total_on_hand, 0) AS inv_on_hand,
        CASE 
            WHEN COALESCE(ic.total_on_hand, 0) > 0 THEN 'In Stock'
            ELSE 'Out of Stock'
        END AS stock_status
    FROM 
        TopSales ts
    LEFT JOIN 
        InventoryCheck ic ON ts.ws_item_sk = ic.inv_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.ws_order_number,
    ss.net_price,
    ss.inv_on_hand,
    ss.stock_status,
    CASE 
        WHEN ss.stock_status = 'In Stock' THEN ss.net_price * 0.9
        ELSE ss.net_price * 1.1
    END AS adjusted_price
FROM 
    SalesSummary ss
WHERE 
    ss.net_price > (
        SELECT AVG(net_price) FROM SalesSummary
    ) 
UNION 
SELECT 
    NULL AS ws_item_sk,
    NULL AS ws_order_number,
    NULL AS net_price,
    NULL AS inv_on_hand,
    'No Sales' AS stock_status,
    NULL AS adjusted_price
ORDER BY 
    adjusted_price DESC NULLS LAST;
