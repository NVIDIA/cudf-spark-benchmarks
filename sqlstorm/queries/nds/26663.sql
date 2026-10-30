
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY')
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    GROUP BY 
        c.c_customer_sk, CONCAT(c.c_first_name, ' ', c.c_last_name)
),
TopCustomers AS (
    SELECT 
        full_name,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank,
        c.c_customer_sk
    FROM 
        CustomerPurchases c
)
SELECT 
    tc.full_name,
    tc.total_spent,
    ad.full_address
FROM 
    TopCustomers tc
JOIN 
    AddressDetails ad ON tc.c_customer_sk = ad.ca_address_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
