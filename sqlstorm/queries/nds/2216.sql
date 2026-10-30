
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2023001 AND 2023007
    GROUP BY ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS customer_total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.customer_total_sales,
        RANK() OVER (ORDER BY cs.customer_total_sales DESC) AS customer_rank
    FROM CustomerSales cs
)
SELECT 
    t1.total_quantity,
    t1.total_sales,
    tc.c_first_name,
    tc.c_last_name,
    tc.customer_total_sales
FROM RankedSales t1
JOIN TopCustomers tc ON t1.ws_item_sk = tc.c_customer_sk
WHERE t1.sales_rank <= 10 AND tc.customer_rank <= 5
ORDER BY t1.total_sales DESC, tc.customer_total_sales DESC;
