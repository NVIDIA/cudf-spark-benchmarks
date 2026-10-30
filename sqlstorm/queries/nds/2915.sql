
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.revenue_rank,
        i.i_current_price,
        COALESCE(r.total_quantity * i.i_current_price, 0) AS expected_revenue
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.revenue_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY sr_customer_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > 0 OR cr.total_returns IS NULL
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.expected_revenue,
    CASE 
        WHEN ti.expected_revenue > 1000 THEN 'High'
        WHEN ti.expected_revenue BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS revenue_category
FROM FilteredCustomers f
JOIN TopItems ti ON f.total_returns > 0
ORDER BY ti.expected_revenue DESC;
