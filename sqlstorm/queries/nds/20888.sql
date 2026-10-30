
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS total_orders_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk, 
        SUM(sr.sr_return_quantity) AS total_store_return_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_orders_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
CombinedSales AS (
    SELECT 
        rs.ws_item_sk AS item_sk,
        rs.total_quantity_sold,
        rs.total_net_paid,
        COALESCE(cr.total_return_quantity, 0) AS total_catalog_return_quantity,
        COALESCE(cr.total_orders_returned, 0) AS total_catalog_orders_returned,
        COALESCE(sr.total_store_return_quantity, 0) AS total_store_return_quantity,
        COALESCE(sr.total_store_orders_returned, 0) AS total_store_orders_returned
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.cr_item_sk
    LEFT JOIN 
        SalesReturns sr ON rs.ws_item_sk = sr.sr_item_sk
)
SELECT 
    cs.item_sk,
    cs.total_quantity_sold,
    cs.total_net_paid,
    cs.total_catalog_return_quantity,
    cs.total_catalog_orders_returned,
    cs.total_store_return_quantity,
    cs.total_store_orders_returned,
    (cs.total_net_paid - (cs.total_catalog_return_quantity * (SELECT AVG(cs_ext_sales_price) FROM catalog_sales WHERE cs_item_sk = cs.item_sk))) AS net_sales_after_returns,
    CASE 
        WHEN cs.total_quantity_sold = 0 THEN NULL 
        ELSE (cs.total_store_return_quantity * 1.0 / cs.total_quantity_sold) * 100 
    END AS store_return_rate_percentage
FROM 
    CombinedSales cs
WHERE 
    cs.total_net_paid > 1000
    AND (cs.total_catalog_orders_returned + cs.total_store_orders_returned) > 0
ORDER BY 
    net_sales_after_returns DESC
LIMIT 10;
