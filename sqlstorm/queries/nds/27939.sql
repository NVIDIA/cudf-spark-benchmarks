
WITH FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city AS c_city, ca.ca_state AS c_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 12 AND c.c_birth_day BETWEEN 15 AND 31
),
AggregatedSales AS (
    SELECT 
        c.c_city, 
        c.c_state,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM FilteredCustomers c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_city, c.c_state
),
RankedSales AS (
    SELECT 
        c.c_city AS city, 
        c.c_state AS state, 
        a.total_sales, 
        a.total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_state ORDER BY a.total_sales DESC) AS sales_rank
    FROM AggregatedSales a
    JOIN FilteredCustomers c ON a.c_city = c.c_city AND a.c_state = c.c_state
)
SELECT 
    city, 
    state, 
    total_sales, 
    total_orders, 
    sales_rank
FROM RankedSales
WHERE sales_rank <= 5 
ORDER BY state, sales_rank;
