
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
), 
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
), 
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_net_paid) AS total_store_net_paid
    FROM 
        store_sales ss
    WHERE 
        ss.ss_net_paid > 100
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.ws_sales_price, 0) AS max_sales_price,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ss.total_store_net_paid, 0) AS total_store_net_paid
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rank = 1
LEFT JOIN 
    TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
LEFT JOIN 
    StoreSalesSummary ss ON i.i_item_sk = ss.ss_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    i.i_item_id;
