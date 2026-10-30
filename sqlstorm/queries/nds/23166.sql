
WITH ranked_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS price_rank
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sales_price > 0
),
item_inventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
),
item_returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
)
SELECT
    i.i_item_id,
    COALESCE(s.total_quantity, 0) AS total_available,
    COALESCE(r.total_returns, 0) AS total_returns,
    ra.price_rank,
    ROUND(ra.price_rank * COALESCE(s.total_quantity, 1), 2) AS price_rank_quantity_calculation,
    CASE
        WHEN r.total_returns IS NULL THEN 'No Returns'
        WHEN r.total_return_amount < 0 THEN 'Negative Returns'
        ELSE 'Active Returns'
    END AS return_status
FROM
    item i
LEFT JOIN
    item_inventory s ON i.i_item_sk = s.inv_item_sk
LEFT JOIN
    item_returns r ON i.i_item_sk = r.cr_item_sk
LEFT JOIN
    ranked_sales ra ON i.i_item_sk = ra.cs_item_sk
WHERE
    (i.i_current_price BETWEEN 10.00 AND 100.00 OR i.i_current_price IS NULL)
    AND (s.total_quantity IS NOT NULL OR r.total_returns IS NOT NULL)
ORDER BY
    i.i_item_id,
    return_status DESC NULLS LAST;
