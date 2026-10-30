
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        c.c_customer_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        sd.customer_sk,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return,
        SUM(sr_return_quantity) AS total_returned_items
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    tc.customer_sk,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return, 0) AS total_return,
    COALESCE(rs.total_returned_items, 0) AS total_returned_items,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnStats rs ON tc.customer_sk = rs.sr_customer_sk
LEFT JOIN 
    CustomerAddress ca ON tc.customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    total_sales DESC;
