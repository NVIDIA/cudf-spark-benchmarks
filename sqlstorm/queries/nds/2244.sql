
WITH historical_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales 
    WHERE ws_sold_date_sk >= 20210101 
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_class,
        i.i_category,
        COALESCE(hs.total_sold, 0) AS total_sold,
        COALESCE(hs.total_revenue, 0) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY COALESCE(hs.total_revenue, 0) DESC) AS rank
    FROM item i
    LEFT JOIN historical_sales hs ON i.i_item_sk = hs.ws_item_sk
),
high_revenue_items AS (
    SELECT 
        iad.i_item_sk,
        iad.i_item_desc,
        iad.i_brand,
        iad.i_class,
        iad.i_category,
        iad.total_sold,
        iad.total_revenue
    FROM item_details iad
    WHERE iad.rank = 1 AND iad.total_revenue > 1000 
),
recent_web_returns AS (
    SELECT 
        wr_item_sk, 
        COUNT(wr_order_number) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    WHERE wr_returned_date_sk >= 20230101
    GROUP BY wr_item_sk
)
SELECT 
    hi.i_item_sk,
    hi.i_item_desc,
    hi.i_brand,
    hi.i_class,
    hi.i_category,
    hi.total_sold,
    hi.total_revenue,
    COALESCE(r.return_count, 0) AS return_count,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN hi.total_revenue > r.total_return_amount THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status
FROM high_revenue_items hi
LEFT JOIN recent_web_returns r ON hi.i_item_sk = r.wr_item_sk
ORDER BY hi.total_revenue DESC, return_count ASC;
