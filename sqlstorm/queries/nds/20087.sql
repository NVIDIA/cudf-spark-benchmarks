
WITH  address_cte AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_city IS NOT NULL)
), sales_agg AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count, 
        COALESCE(SUM(ws_net_paid), 0) AS total_revenue
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY ws_item_sk
), return_summary AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_returnamt,
        COUNT(DISTINCT sr_ticket_number) AS unique_tickets
    FROM store_returns 
    GROUP BY sr_item_sk
), final_results AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.total_sales, 0) AS total_sales,
        COALESCE(returns.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(returns.total_returns, 0) > 0 THEN 
                ROUND((COALESCE(sales.total_sales, 0) * 1.0 / COALESCE(returns.total_returns, 1)), 2) 
            ELSE NULL 
        END AS sales_to_return_ratio,
        addr.ca_city,
        addr.ca_state
    FROM item
    LEFT JOIN sales_agg AS sales ON item.i_item_sk = sales.ws_item_sk
    LEFT JOIN return_summary AS returns ON item.i_item_sk = returns.sr_item_sk
    LEFT JOIN address_cte AS addr ON addr.rn = 1  
    WHERE item.i_current_price > (SELECT AVG(i_current_price) FROM item)
    UNION ALL
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        MAX(sales.total_sales) AS total_sales,
        SUM(returns.total_returns) AS total_returns,
        CASE 
            WHEN SUM(returns.total_returns) > 0 THEN 
                ROUND((MAX(sales.total_sales) / SUM(returns.total_returns)), 2) 
            ELSE NULL 
        END AS sales_to_return_ratio,
        NULL AS ca_city,
        NULL AS ca_state
    FROM item
    LEFT JOIN sales_agg AS sales ON item.i_item_sk = sales.ws_item_sk
    LEFT JOIN return_summary AS returns ON item.i_item_sk = returns.sr_item_sk
    WHERE item.i_current_price IS NULL
    GROUP BY item.i_item_id, item.i_item_desc
)
SELECT * 
FROM final_results
ORDER BY ca_state, total_sales DESC, i_item_id 
LIMIT 100;
