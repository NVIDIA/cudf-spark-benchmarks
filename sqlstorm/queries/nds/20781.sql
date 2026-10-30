
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL 
        AND i.i_current_price IS NOT NULL 
        AND (i.i_class_id IN (SELECT DISTINCT i_class_id FROM item WHERE i_manufact_id IS NOT NULL) 
             OR i.i_brand_id IN (SELECT DISTINCT i_brand_id FROM item WHERE i_current_price > 10))
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        rp.ws_item_sk,
        rp.total_quantity,
        rp.total_sales
    FROM 
        RankedSales rp
    WHERE 
        rp.sales_rank <= 5
),
ReturnDetails AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_sales
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 1 AND 31
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    tp.ws_item_sk,
    tp.total_quantity,
    tp.total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_returned_sales, 0) AS total_returned_sales,
    (tp.total_sales - COALESCE(rd.total_returned_sales, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(rd.total_returns, 0) = 0 THEN 'No Returns' 
        WHEN COALESCE(rd.total_returns, 0) > tp.total_quantity THEN 'Over Returned' 
        ELSE 'Normal Return'
    END AS return_status
FROM 
    TopProducts tp
LEFT JOIN 
    ReturnDetails rd ON tp.ws_item_sk = rd.wr_item_sk
ORDER BY 
    net_sales DESC, total_sales DESC
LIMIT 10;
