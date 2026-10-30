
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS last_purchase_date,
        a.full_address,
        s.total_spent,
        s.order_count
    FROM 
        customer c
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)
SELECT 
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS customer_name,
    cd.full_address,
    cd.total_spent,
    cd.order_count,
    MAX(cd.last_purchase_date) AS last_purchase
FROM 
    CustomerDetails cd
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.full_address, cd.total_spent, cd.order_count
ORDER BY 
    total_spent DESC
LIMIT 10;
