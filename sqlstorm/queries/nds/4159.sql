
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 1)
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(tr.total_return_amount, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
)
SELECT 
    s.ws_item_sk,
    id.i_item_desc,
    id.total_returned,
    id.total_return_amount,
    SUM(s.ws_quantity) AS total_quantity_sold,
    AVG(s.ws_sales_price) AS avg_sales_price,
    CASE 
        WHEN COUNT(DISTINCT s.ws_order_number) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS sold_this_month
FROM 
    RankedSales s
JOIN 
    ItemDetails id ON s.ws_item_sk = id.i_item_sk
WHERE 
    s.rn = 1
GROUP BY 
    s.ws_item_sk, id.i_item_desc, id.total_returned, id.total_return_amount
HAVING 
    SUM(s.ws_quantity) > 100
ORDER BY 
    avg_sales_price DESC;
