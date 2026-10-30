
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn,
        COALESCE(SUM(cs.cs_quantity) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 0) AS total_catalog_quantity
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
),
TotalSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
SubQuery AS (
    SELECT 
        a.c_customer_id,
        COALESCE(MAX(ws.ws_net_profit), 0) AS max_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer a
    LEFT JOIN 
        web_sales ws ON a.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        a.c_customer_id
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_quantity,
    r.ws_sales_price,
    r.ws_net_profit,
    ts.total_net_profit,
    ts.total_orders,
    sq.c_customer_id,
    sq.max_profit,
    sq.order_count
FROM 
    RankedSales r
JOIN 
    TotalSales ts ON r.ws_order_number = ts.ws_order_number
JOIN 
    SubQuery sq ON sq.order_count > 5
WHERE 
    r.rn = 1
    AND r.total_catalog_quantity > 0
ORDER BY 
    ts.total_net_profit DESC, sq.max_profit DESC;
