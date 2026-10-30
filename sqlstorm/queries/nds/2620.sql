
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_paid,
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        ca.ca_country = 'USA'
),
SalesEvaluation AS (
    SELECT 
        t.customer_id,
        t.c_first_name,
        t.c_last_name,
        t.total_net_paid,
        t.sales_rank,
        CASE 
            WHEN t.sales_rank <= 10 THEN 'Top Performer'
            ELSE 'Regular Customer'
        END AS performance_category
    FROM 
        TopCustomers t
)
SELECT 
    se.*,
    AVG(se.total_net_paid) OVER () AS average_sales,
    (SELECT COUNT(*) FROM customer WHERE c_birth_month = 12) AS total_customers_born_in_december
FROM 
    SalesEvaluation se
ORDER BY 
    se.sales_rank;
