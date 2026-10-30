
WITH  sale_totals AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 1 AND 100
    GROUP BY cs_item_sk
    UNION ALL
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_ext_sales_price) DESC) AS rank
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 1 AND 100
    GROUP BY s.ss_item_sk
)
, combined_sales AS (
    SELECT 
        st.cs_item_sk AS item_sk,
        COALESCE(st.total_sales, 0) + COALESCE(ss.total_sales, 0) AS grand_total_sales,
        COALESCE(st.total_orders, 0) + COALESCE(ss.total_orders, 0) AS grand_total_orders
    FROM (
        SELECT cs_item_sk, SUM(cs_ext_sales_price) AS total_sales, COUNT(cs_order_number) AS total_orders
        FROM catalog_sales
        GROUP BY cs_item_sk
    ) st
    FULL OUTER JOIN (
        SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_orders
        FROM store_sales
        GROUP BY ss_item_sk
    ) ss ON st.cs_item_sk = ss.ss_item_sk
)
SELECT 
    item_sk,
    grand_total_sales,
    grand_total_orders,
    grand_total_sales / NULLIF(grand_total_orders, 0) AS avg_sales_per_order
FROM combined_sales
WHERE grand_total_sales > 10000
AND item_sk IN (
    SELECT i_item_sk 
    FROM item 
    WHERE i_category = 'Electronics'
)
AND EXISTS (
    SELECT 1 
    FROM customer c 
    WHERE c.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_order_number IN (
            SELECT wr_order_number 
            FROM web_returns 
            WHERE wr_return_quantity > 0
        )
    )
)
ORDER BY avg_sales_per_order DESC
LIMIT 10;
