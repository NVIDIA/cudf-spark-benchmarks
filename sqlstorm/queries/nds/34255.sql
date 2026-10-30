
WITH  sales_rank AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
sales_summary AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales_rank.total_sales,
        COALESCE(NULLIF(item.i_current_price, 0), 1) AS effective_price,
        ROUND(sales_rank.total_sales * COALESCE(NULLIF(item.i_current_price, 0), 1), 2) AS total_revenue,
        sales_rank.rank
    FROM item
    JOIN sales_rank ON item.i_item_sk = sales_rank.ws_item_sk
),
customer_counts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_state
)
SELECT 
    ss.i_product_name,
    ss.total_sales,
    ss.effective_price,
    ss.total_revenue,
    cc.customer_count,
    CASE 
        WHEN ss.rank <= 10 THEN 'Top Selling'
        ELSE 'Others'
    END AS sales_category
FROM sales_summary ss
LEFT JOIN customer_counts cc ON ss.i_product_name LIKE '%gear%'
ORDER BY ss.total_revenue DESC, cc.customer_count DESC
LIMIT 25;
