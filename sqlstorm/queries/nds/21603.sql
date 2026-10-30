
WITH  CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ss.ss_item_sk) AS store_items_purchased,
        COUNT(ws.ws_item_sk) AS web_items_purchased,
        SUM(ss.ss_sales_price) AS total_store_spent,
        SUM(ws.ws_sales_price) AS total_web_spent
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COUNT(ss.ss_item_sk) + COUNT(ws.ws_item_sk) > 0
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    COALESCE(cp.store_items_purchased, 0) AS store_items,
    COALESCE(cp.web_items_purchased, 0) AS web_items,
    COALESCE(cp.total_store_spent, 0) AS total_store,
    COALESCE(cp.total_web_spent, 0) AS total_web,
    CASE 
        WHEN COALESCE(cp.total_store_spent, 0) > COALESCE(cp.total_web_spent, 0) THEN 'Store'
        WHEN COALESCE(cp.total_web_spent, 0) > COALESCE(cp.total_store_spent, 0) THEN 'Web'
        ELSE 'Equal'
    END AS preferred_channel,
    CASE 
        WHEN COALESCE(cp.store_items_purchased, 0) = 0 AND COALESCE(cp.web_items_purchased, 0) = 0 THEN 'No purchases'
        ELSE 'Purchasing customer'
    END AS customer_status
FROM CustomerPurchases cp
WHERE 
    cp.c_customer_sk IN (
        SELECT 
            DISTINCT cr_returning_customer_sk
        FROM catalog_returns
        WHERE cr_return_quantity > 0
        EXCEPT
        SELECT 
            DISTINCT wr_returning_customer_sk
        FROM web_returns
        WHERE wr_return_quantity <= 0
    )
ORDER BY 
    cp.total_store_spent + cp.total_web_spent DESC, 
    cp.c_last_name, 
    cp.c_first_name;
