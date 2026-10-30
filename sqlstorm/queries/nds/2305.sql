
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2000000 AND 2005000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.total_sales,
        rc.order_count
    FROM 
        RankedSales rc
    WHERE 
        rc.sales_rank <= 10
),
CustomerLocations AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        tc.total_sales
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        TopCustomers tc ON c.c_customer_id = tc.c_customer_id
),
SalesSummary AS (
    SELECT 
        cl.ca_city,
        cl.ca_state,
        COUNT(DISTINCT tc.c_customer_id) AS customer_count,
        SUM(tc.total_sales) AS total_sales_amount
    FROM 
        CustomerLocations cl
    JOIN 
        TopCustomers tc ON cl.total_sales = tc.total_sales
    GROUP BY 
        cl.ca_city, cl.ca_state
)
SELECT 
    s.ca_city,
    s.ca_state,
    COALESCE(s.customer_count, 0) AS customer_count,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    CASE 
        WHEN s.total_sales_amount IS NULL THEN 'No Sales'
        WHEN s.total_sales_amount > 10000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM 
    SalesSummary s
FULL OUTER JOIN 
    customer_address ca ON s.ca_city = ca.ca_city AND s.ca_state = ca.ca_state
ORDER BY 
    s.total_sales_amount DESC NULLS LAST;
