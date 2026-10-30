
WITH RankedSales AS (
    SELECT 
        s.s_store_id,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY 
        s.s_store_id, ws.ws_item_sk, ws.ws_order_number, ws.ws_quantity, ws.ws_sales_price
),
TotalReturns AS (
    SELECT 
        item_sk,
        SUM(return_quantity) AS total_returns
    FROM (
        SELECT 
            wr_item_sk AS item_sk, 
            wr_return_quantity AS return_quantity 
        FROM web_returns
        UNION ALL
        SELECT 
            cr_item_sk AS item_sk, 
            cr_return_quantity AS return_quantity 
        FROM catalog_returns
    ) AS combined_returns
    GROUP BY item_sk
)
SELECT 
    r.s_store_id,
    r.ws_item_sk,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_sales_price,
    COALESCE(tr.total_returns, 0) AS total_returns,
    r.ws_quantity - COALESCE(tr.total_returns, 0) AS net_sales
FROM 
    RankedSales r
LEFT JOIN 
    TotalReturns tr ON r.ws_item_sk = tr.item_sk
WHERE 
    r.sales_rank <= 5
    AND r.ws_sales_price IS NOT NULL
    AND r.ws_quantity > 0
ORDER BY 
    r.s_store_id, 
    net_sales DESC;
