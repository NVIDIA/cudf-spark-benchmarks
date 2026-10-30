
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
InventoryData AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_date_sk, inv_item_sk
)
SELECT 
    dd.d_date AS sale_date,
    id.inv_item_sk,
    id.total_on_hand,
    COALESCE(sd.total_sold, 0) AS total_sold,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(cr.total_return_tax, 0) AS total_return_tax,
    (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales_amount
FROM 
    date_dim dd
LEFT JOIN InventoryData id ON dd.d_date_sk = id.inv_date_sk
LEFT JOIN SalesData sd ON dd.d_date_sk = sd.ws_sold_date_sk AND id.inv_item_sk = sd.ws_item_sk
LEFT JOIN CustomerReturns cr ON dd.d_date_sk = cr.sr_returned_date_sk AND id.inv_item_sk = cr.sr_item_sk
WHERE 
    dd.d_year = 2023
ORDER BY 
    sale_date, id.inv_item_sk;
