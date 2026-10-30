
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    COALESCE(ROUND(SUM(CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_ext_ship_cost END), 2), 0) AS total_ship_cost,
    COALESCE(ROUND(SUM(CASE WHEN ws.ws_ship_mode_sk IS NULL THEN ws.ws_net_paid END), 2), 0) AS total_net_paid_without_ship
FROM HighValueCustomers hvc
LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count
ORDER BY hvc.total_sales DESC
LIMIT 10;
