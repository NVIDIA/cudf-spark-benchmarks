
WITH CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
InventoryStatus AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM
        inventory
    GROUP BY
        inv_item_sk
),
LatestPromotions AS (
    SELECT
        p_item_sk,
        MAX(p_start_date_sk) AS latest_start_date
    FROM
        promotion
    WHERE
        p_discount_active = 'Y'
    GROUP BY
        p_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(ws_order_number) AS total_sales_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
)

SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(inv.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    CASE
        WHEN COALESCE(s.total_sales_amount, 0) = 0 THEN 'No Sales'
        ELSE CAST(ROUND((COALESCE(r.total_return_amount, 0) / COALESCE(s.total_sales_amount, 1)) * 100, 2) AS STRING) || '%' 
    END AS return_percentage,
    CASE
        WHEN p.p_item_sk IS NOT NULL THEN 'Active Promotion'
        ELSE 'No Active Promotion'
    END AS promotion_status
FROM
    item i
LEFT JOIN SalesData s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN CustomerReturns r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN InventoryStatus inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN LatestPromotions p ON i.i_item_sk = p.p_item_sk
ORDER BY
    i.i_item_id;
