
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS item_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_order_number
),
HighValueReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
),
FinalSalesData AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_paid,
        COALESCE(hv.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(hv.total_returned_amount, 0) AS returned_amount,
        (rs.total_net_paid - COALESCE(hv.total_returned_amount, 0)) AS net_sales_after_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        HighValueReturns hv ON rs.ws_item_sk = hv.wr_item_sk
    WHERE 
        rs.item_rank = 1
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_quantity,
    fs.total_net_paid,
    fs.returned_quantity,
    fs.returned_amount,
    fs.net_sales_after_returns
FROM 
    FinalSalesData fs
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
WHERE 
    fs.net_sales_after_returns > 1000 
ORDER BY 
    fs.net_sales_after_returns DESC
LIMIT 10;
