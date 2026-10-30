
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_discount_amt,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sales_price > 0
),
HighValueReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned
    FROM
        catalog_returns
    WHERE
        cr_return_quantity IS NOT NULL
        AND cr_return_amount > 100 
    GROUP BY
        cr_item_sk
),
AggregateInventory AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM
        inventory
    WHERE
        inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        inv_item_sk
),
FinalResults AS (
    SELECT
        COALESCE(a.inv_item_sk, b.ws_item_sk) AS item_sk,
        COALESCE(a.total_on_hand, 0) AS total_inventory,
        b.sales_rank,
        COALESCE(h.total_returned, 0) AS total_returns
    FROM
        AggregateInventory a
    FULL OUTER JOIN
        RankedSales b ON a.inv_item_sk = b.ws_item_sk
    LEFT JOIN
        HighValueReturns h ON b.ws_item_sk = h.cr_item_sk
    WHERE
        (b.sales_rank IS NULL OR b.sales_rank <= 5)
        AND (a.total_on_hand > 50 OR h.total_returned > 10)
)
SELECT
    f.item_sk,
    f.total_inventory,
    f.sales_rank,
    f.total_returns,
    (CASE
        WHEN f.total_returns > 10 THEN 'High Return'
        WHEN f.total_inventory < 30 THEN 'Low Stock'
        ELSE 'Stable'
    END) AS stock_status
FROM
    FinalResults f
WHERE
    f.sales_rank IS NOT NULL
ORDER BY
    f.total_returns DESC, f.total_inventory ASC;
