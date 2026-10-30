
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_return_summary AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
aggregated_item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value,
        COALESCE(ci.total_return_amount, 0) AS total_return_amount,
        ci.total_returns
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer_return_summary ci ON ws.ws_bill_customer_sk = ci.cr_returning_customer_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, ci.total_return_amount, ci.total_returns
)
SELECT 
    aii.i_item_sk,
    aii.i_item_desc,
    aii.total_quantity_sold,
    aii.total_sales_value,
    ranked.price_rank,
    aii.total_return_amount,
    aii.total_returns,
    CASE 
        WHEN aii.total_sales_value IS NULL THEN 'No Sales'
        WHEN aii.total_sales_value > 1000 THEN 'High Sales'
        ELSE 'Regular Sales' 
    END AS sales_category
FROM 
    aggregated_item_info aii
LEFT JOIN 
    ranked_sales ranked ON aii.i_item_sk = ranked.ws_item_sk
WHERE 
    aii.total_quantity_sold > 5 
    AND (ranked.price_rank IS NULL OR ranked.price_rank < 5)
ORDER BY 
    aii.total_sales_value DESC, aii.i_item_desc;
