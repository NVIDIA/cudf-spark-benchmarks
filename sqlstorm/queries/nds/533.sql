WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001 AND d.d_moy IN (1, 2, 3)  
    )
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
    GROUP BY wr.wr_item_sk
),
InventoryData AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    sd.ws_item_sk,
    COALESCE(sd.total_quantity, 0) AS total_sold,
    COALESCE(cr.total_return_qty, 0) AS total_returned,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    COALESCE(id.total_quantity_on_hand, 0) AS quantity_on_hand,
    (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amt, 0)) AS net_revenue
FROM SalesData sd
LEFT JOIN CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
LEFT JOIN InventoryData id ON sd.ws_item_sk = id.i_item_sk
WHERE sd.sales_rank <= 5  
ORDER BY net_revenue DESC;