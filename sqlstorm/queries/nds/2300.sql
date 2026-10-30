
WITH SalesStats AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
TopSales AS (
    SELECT
        ss.ws_item_sk,
        MAX(ss.ws_ext_sales_price) AS max_sales_price,
        SUM(ss.ws_quantity) AS total_quantity_sold
    FROM
        SalesStats ss
    WHERE
        ss.rank <= 5
    GROUP BY
        ss.ws_item_sk
),
InventoryStats AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    coalesce(i.inv_item_sk, t.ws_item_sk) AS item_sk,
    i.total_inventory,
    t.total_quantity_sold,
    t.max_sales_price,
    CASE
        WHEN i.total_inventory IS NULL THEN 'OUT OF STOCK'
        WHEN i.total_inventory < t.total_quantity_sold THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END AS stock_status
FROM
    TopSales t
FULL OUTER JOIN
    InventoryStats i ON t.ws_item_sk = i.inv_item_sk
WHERE
    (t.total_quantity_sold > 0 OR i.total_inventory IS NOT NULL)
ORDER BY
    stock_status, max_sales_price DESC;
