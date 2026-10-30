
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(tr.total_returned_amount, 0) AS total_returned_amount,
        (sd.total_sales_amount - COALESCE(tr.total_returned_amount, 0)) AS net_sales_amount,
        sd.sales_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        TotalReturns tr ON sd.ws_item_sk = tr.wr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_quantity_sold,
    fs.total_sales_amount,
    fs.total_returned,
    fs.total_returned_amount,
    fs.net_sales_amount,
    fs.sales_rank
FROM 
    FinalSales fs
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
WHERE 
    fs.net_sales_amount > 0
ORDER BY 
    fs.net_sales_amount DESC
LIMIT 10;
