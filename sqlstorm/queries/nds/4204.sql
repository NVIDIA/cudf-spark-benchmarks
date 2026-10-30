
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
    HAVING 
        SUM(sr.sr_return_quantity) > 0
),
SalesWithReturns AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_ext_sales_price,
        COALESCE(cr.TotalReturns, 0) AS CustomerReturns
    FROM 
        RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_order_number = cr.sr_customer_sk
)
SELECT 
    swr.ws_order_number,
    swr.ws_item_sk,
    swr.ws_ext_sales_price,
    swr.CustomerReturns,
    (CASE 
        WHEN swr.CustomerReturns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END) AS ReturnStatus,
    (w.w_warehouse_name || ' - ' || w.w_city || ', ' || w.w_state) AS WarehouseLocation
FROM 
    SalesWithReturns swr
JOIN 
    inventory i ON swr.ws_item_sk = i.inv_item_sk
JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    swr.CustomerReturns IS NOT NULL
ORDER BY 
    swr.ws_ext_sales_price DESC, 
    swr.CustomerReturns ASC;
