
WITH InventorySummary AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MAX(i.i_current_price) AS current_price
    FROM
        inventory inv
    JOIN
        item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY
        inv.inv_item_sk
),
SalesPerformance AS (
    SELECT
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
ReturnedItems AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY
        wr.wr_item_sk
)
SELECT
    i.i_item_id,
    inv.total_quantity,
    sp.total_orders,
    sp.total_revenue,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_returned_amount, 0.00) AS total_returned_amount,
    CASE 
        WHEN sp.total_revenue > 10000 THEN 'High Performer'
        WHEN sp.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM
    InventorySummary inv
JOIN
    SalesPerformance sp ON inv.inv_item_sk = sp.ws_item_sk
LEFT JOIN
    ReturnedItems ri ON inv.inv_item_sk = ri.wr_item_sk
JOIN
    item i ON i.i_item_sk = inv.inv_item_sk
WHERE
    inv.total_quantity > 10
ORDER BY
    inv.total_quantity DESC, sp.total_revenue DESC;
