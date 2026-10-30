
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank,
        COALESCE(NULLIF(ws.ws_net_paid, 0), ws.ws_net_paid_inc_tax) AS EffectiveNetPaid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 
              AND d.d_month_seq IN (SELECT DISTINCT d_month_seq 
                                     FROM date_dim 
                                     WHERE d_year = 2023 
                                       AND d_dow = 5) 
              AND d.d_current_day = 'Y'
        )
) 
SELECT 
    ITEM.i_item_id,
    ITEM.i_product_name,
    COALESCE(SUM(RS.EffectiveNetPaid), 0) AS TotalEffectiveSales,
    COUNT(DISTINCT RS.ws_order_number) AS OrderCount,
    AVG(RS.ws_sales_price) AS AverageSalesPrice
FROM 
    item ITEM
LEFT JOIN 
    RankedSales RS ON ITEM.i_item_sk = RS.ws_item_sk
GROUP BY 
    ITEM.i_item_id,
    ITEM.i_product_name
HAVING 
    COALESCE(SUM(RS.EffectiveNetPaid), 0) > (SELECT AVG(EffectiveNetPaid) 
                                               FROM RankedSales)
ORDER BY 
    TotalEffectiveSales DESC
LIMIT 10;
