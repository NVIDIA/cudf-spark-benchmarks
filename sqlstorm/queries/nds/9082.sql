
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN
        (SELECT 
            c_customer_id AS customer_id, 
            c_first_name AS first_name, 
            c_last_name AS last_name 
         FROM
            customer) c ON cs.c_customer_id = c.customer_id
),
StoreSales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        s.s_store_id, s.s_store_name
)
SELECT 
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.total_orders,
    ss.total_store_sales,
    ss.total_transactions,
    tc.sales_rank
FROM 
    TopCustomers tc
JOIN 
    StoreSales ss ON ss.total_store_sales > 10000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
