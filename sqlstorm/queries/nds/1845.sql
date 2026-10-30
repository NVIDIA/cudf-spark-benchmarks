
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458849 AND 2458914 
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Standard', 'Premium')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_credit_rating
    HAVING SUM(ws_ext_sales_price) > 1000
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        AVG(ss_net_paid) AS average_transaction_value
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss_sold_date_sk >= 2458849 
    GROUP BY s.s_store_sk, s.s_store_name
)

SELECT 
    a.total_quantity,
    a.total_sales,
    b.c_first_name,
    b.c_last_name,
    b.order_count,
    b.total_spent,
    c.s_store_name,
    c.total_store_sales,
    c.average_transaction_value
FROM RankedSales a
FULL OUTER JOIN HighValueCustomers b ON a.ws_item_sk = b.c_customer_sk
FULL OUTER JOIN TopStores c ON b.order_count > 10
WHERE a.total_sales IS NOT NULL OR b.total_spent IS NOT NULL OR c.total_store_sales IS NOT NULL
ORDER BY a.total_sales DESC, b.total_spent DESC, c.total_store_sales DESC
LIMIT 100;
