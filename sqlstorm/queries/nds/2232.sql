WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
                                AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY ws_item_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
),
ReturnedSales AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    COALESCE(id.total_inventory, 0) AS total_inventory,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) > 0 THEN (COALESCE(rd.total_returns, 0) / COALESCE(sd.total_quantity, 0)) * 100 
        ELSE 0 
    END AS return_rate_percentage
FROM item i
LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN InventoryData id ON i.i_item_sk = id.inv_item_sk
LEFT JOIN ReturnedSales rd ON i.i_item_sk = rd.sr_item_sk
WHERE i.i_current_price IS NOT NULL
AND (sd.sales_rank <= 10 OR sd.sales_rank IS NULL) 
ORDER BY total_sales DESC, i.i_item_id;