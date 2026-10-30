
WITH RankedReturns AS (
    SELECT 
        cr_returned_date_sk,
        cr_item_sk,
        cr_order_number,
        cr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY cr_returned_date_sk DESC) AS rnk
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS unique_orders
    FROM 
        RankedReturns
    WHERE 
        rnk <= 5
    GROUP BY 
        cr_item_sk
),
TopItems AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_id,
        ir.i_item_desc,
        ar.total_returned,
        ar.unique_orders,
        ROW_NUMBER() OVER (ORDER BY ar.total_returned DESC) AS item_rank
    FROM 
        item ir
    LEFT JOIN 
        AggregatedReturns ar ON ir.i_item_sk = ar.cr_item_sk
    WHERE 
        ir.i_current_price IS NOT NULL
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    COALESCE(ti.total_returned, 0) AS total_returned,
    COALESCE(ti.unique_orders, 0) AS unique_orders,
    CASE 
        WHEN ti.total_returned > 0 THEN 'High Return Rate'
        WHEN ti.total_returned IS NULL THEN 'No Returns'
        ELSE 'Low Return Rate'
    END AS return_rate_category,
    (SELECT COUNT(*) 
     FROM customer c
     WHERE c.c_preferred_cust_flag = 'Y'
     AND c.c_current_cdemo_sk IS NOT NULL) AS active_preferred_customers,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_item_sk = ti.i_item_sk 
     AND ws_sold_date_sk > 20240101) AS web_sales_recent_customers
FROM 
    TopItems ti
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_returned DESC, 
    ti.i_item_id;
