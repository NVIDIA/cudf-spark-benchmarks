
WITH  SalesData AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS number_of_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ss_store_sk, ss_item_sk
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(total_sales) AS store_total_sales
    FROM SalesData
    JOIN store ON SalesData.ss_store_sk = store.s_store_sk
    GROUP BY s_store_sk, s_store_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_spent,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages_viewed
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    s.s_store_name AS store_name,
    ss.ss_item_sk AS item_sk,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.total_sales) AS total_sales_amount,
    AVG(cs.total_spent) AS avg_spent_per_customer
FROM SalesData ss
JOIN TopStores s ON ss.ss_store_sk = s.s_store_sk
JOIN CustomerStats cs ON cs.total_orders > 5
LEFT JOIN customer c ON c.c_customer_sk = ss.ss_item_sk 
WHERE s.store_total_sales > 10000
GROUP BY s.s_store_name, ss.ss_item_sk
HAVING SUM(ss.total_sales) > 5000
ORDER BY total_sales_amount DESC;
