
WITH CustomerSales AS (
    SELECT
        C.c_customer_id,
        C.c_birth_year,
        SUM(WS.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT WS.ws_order_number) AS number_of_orders
    FROM customer C
    JOIN web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
    WHERE WS.ws_ship_date_sk IS NOT NULL
    GROUP BY C.c_customer_id, C.c_birth_year
),
SalesSummary AS (
    SELECT
        cs.c_customer_id,
        cs.c_birth_year,
        cs.total_web_sales,
        cs.number_of_orders,
        RANK() OVER (PARTITION BY cs.c_birth_year ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM CustomerSales cs
),
TopSales AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        ss.total_web_sales,
        ss.number_of_orders
    FROM SalesSummary ss
    JOIN customer c ON c.c_customer_id = ss.c_customer_id
    WHERE ss.sales_rank <= 5
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    COALESCE(ts.total_web_sales, 0) AS total_web_sales,
    COALESCE(ts.number_of_orders, 0) AS number_of_orders,
    CASE
        WHEN ts.number_of_orders IS NULL THEN 'No Orders'
        WHEN ts.number_of_orders > 10 THEN 'Frequent Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_category
FROM customer c
LEFT JOIN TopSales ts ON c.c_customer_id = ts.c_customer_id
WHERE c.c_birth_year BETWEEN 1980 AND 2000
ORDER BY c.c_birth_year DESC, total_web_sales DESC;

