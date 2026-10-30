
WITH  SalesData AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_ext_sales_price, 
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= 20220101
), 
CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_ship_date_sk) AS last_purchase_date
    FROM SalesData sd
    JOIN customer c ON sd.ws_item_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        cp.total_spent,
        cp.total_orders,
        cp.last_purchase_date,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS ranking
    FROM CustomerPurchase cp
    JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.total_spent,
    tc.total_orders,
    tc.last_purchase_date,
    (SELECT COUNT(DISTINCT wp.wp_web_page_sk) 
     FROM web_page wp
     WHERE wp.wp_creation_date_sk < tc.last_purchase_date) AS unique_web_pages_visited
FROM TopCustomers tc
WHERE tc.ranking <= 10
ORDER BY tc.total_spent DESC;
