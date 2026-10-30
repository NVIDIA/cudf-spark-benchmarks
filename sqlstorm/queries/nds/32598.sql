
WITH  ProductSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighSales AS (
    SELECT 
        ps.ws_item_sk,
        ps.total_quantity, 
        ps.total_sales
    FROM ProductSales ps
    WHERE ps.rank <= 10
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ws_sales_price) > 1000
),
CustomerAddress AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_zip) AS city_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.order_count,
        tc.total_spent,
        ca.ca_city,
        ca.ca_state,
        ps.total_quantity,
        ps.total_sales
    FROM TopCustomers tc
    LEFT JOIN CustomerAddress ca ON tc.c_customer_sk = ca.c_customer_sk AND ca.city_rank = 1
    LEFT JOIN HighSales ps ON tc.c_customer_sk = ps.ws_item_sk 
)
SELECT 
    f.c_customer_sk,
    f.order_count,
    f.total_spent,
    f.ca_city,
    f.ca_state,
    COALESCE(f.total_quantity, 0) AS total_quantity,
    COALESCE(f.total_sales, 0) AS total_sales
FROM FinalReport f
ORDER BY f.total_spent DESC
LIMIT 100;
