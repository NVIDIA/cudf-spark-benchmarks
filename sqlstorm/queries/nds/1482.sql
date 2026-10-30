WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerAddress AS (
    SELECT 
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ca.c_customer_id
    FROM 
        customer_address a
    JOIN 
        customer ca ON a.ca_address_sk = ca.c_current_addr_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    COALESCE(ca.ca_state, 'Unknown State') AS state,
    COALESCE(ca.ca_country, 'Unknown Country') AS country,
    tc.total_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerAddress ca ON tc.c_customer_id = ca.c_customer_id
ORDER BY 
    total_sales DESC;