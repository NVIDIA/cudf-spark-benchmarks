
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date = DATE '2023-01-01')
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = DATE '2023-12-31')
    GROUP BY
        ws.ws_item_sk
),
ReturnData AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
InventoryStatus AS (
    SELECT
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM
        inventory inv
    WHERE
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY
        inv.inv_item_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    coalesce(s.total_sales, 0) AS total_sales,
    coalesce(r.total_returns, 0) AS total_returns,
    i.avg_quantity_on_hand,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No sales'
        WHEN r.total_returns IS NULL THEN 'No returns'
        ELSE 'Normal'
    END AS sales_status
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    SalesData s ON s.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand_id IS NULL)
LEFT JOIN
    ReturnData r ON r.wr_item_sk = s.ws_item_sk
LEFT JOIN
    InventoryStatus i ON i.inv_item_sk = s.ws_item_sk
WHERE
    ca.ca_state IS NOT NULL OR (ca.ca_zip IS NULL AND ca.ca_city = 'Unknown')
ORDER BY
    c.c_customer_id,
    total_sales DESC,
    total_returns ASC;

