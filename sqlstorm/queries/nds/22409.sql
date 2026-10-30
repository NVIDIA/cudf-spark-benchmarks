
WITH  catalog_cte AS (
    SELECT cp_catalog_page_sk, cp_catalog_page_id, cp_department, 
           ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY cp_catalog_page_sk) AS rn
    FROM catalog_page
    WHERE cp_start_date_sk BETWEEN 1 AND 10000
),
customer_high_value AS (
    SELECT c_customer_sk, 
           MAX(cd_purchase_estimate) AS max_purchase,
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
    WHERE cd_credit_rating = 'Excellent' AND 
           c_birth_year IS NOT NULL 
    GROUP BY c_customer_sk 
    HAVING MAX(cd_purchase_estimate) > 5000
),
sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
inventory_check AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_on_hand,
        'Low Stock' AS stock_status
    FROM inventory
    WHERE inv_quantity_on_hand < 10
    GROUP BY inv_item_sk
),
customer_returns AS (
    SELECT 
        wr_returned_date_sk,
        COUNT(DISTINCT wr_returning_customer_sk) AS num_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
    GROUP BY wr_returned_date_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    SUM(cs.total_net_paid) AS overall_sales,
    COALESCE(ic.total_on_hand, 0) AS inventory_on_hand,
    CASE 
        WHEN SUM(cs.total_net_paid) IS NULL THEN 'No Sales'
        WHEN SUM(cs.total_net_paid) > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    r.num_returns,
    r.total_return_amt
FROM customer c 
LEFT JOIN customer_high_value chv ON c.c_customer_sk = chv.c_customer_sk
LEFT JOIN sales_summary cs ON cs.ws_item_sk IN (
    SELECT i_item_sk 
    FROM item 
    WHERE i_current_price > 20 
    AND i_item_desc LIKE '%premium%'
) 
LEFT JOIN inventory_check ic ON ic.inv_item_sk = cs.ws_item_sk
LEFT JOIN customer_returns r ON r.wr_returned_date_sk IN (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_year = 2023
) 
WHERE c.c_birth_country = 'USA' 
AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_month > 6)
GROUP BY c.c_first_name, c.c_last_name, c.c_email_address, ic.total_on_hand, r.num_returns, r.total_return_amt
HAVING COALESCE(SUM(cs.total_net_paid), 0) > 5000
ORDER BY overall_sales DESC, c.c_last_name ASC;
