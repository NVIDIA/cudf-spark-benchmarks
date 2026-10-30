
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) as rn
    FROM 
        store_returns
), 
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(NULLIF(i_brand, ''), 'Unknown') AS item_brand
    FROM 
        item
)
SELECT 
    id.i_item_desc,
    id.item_brand,
    ag.total_quantity_sold,
    ag.unique_orders,
    COALESCE(rr.sr_return_quantity, 0) AS returns_last_sale,
    CASE 
        WHEN ag.total_quantity_sold > 1000 THEN 'High Volume'
        WHEN ag.total_quantity_sold BETWEEN 500 AND 1000 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category,
    CASE 
        WHEN rr.rn = 1 THEN 'Most Recent Return'
        ELSE 'Not Most Recent Return'
    END AS return_recency
FROM 
    ItemDetails id
LEFT JOIN 
    AggregateSales ag ON id.i_item_sk = ag.ws_item_sk
LEFT JOIN 
    RankedReturns rr ON id.i_item_sk = rr.sr_item_sk
WHERE 
    (ag.total_quantity_sold IS NOT NULL OR rr.sr_return_quantity IS NOT NULL)
    AND (LOWER(id.item_brand) LIKE '%brand%' OR id.item_brand IS NULL)
ORDER BY 
    ag.total_quantity_sold DESC,
    id.i_item_desc ASC
LIMIT 50;
