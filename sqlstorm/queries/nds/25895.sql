
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
EnrichedCustomerData AS (
    SELECT 
        cust.c_customer_sk,
        cust.full_name,
        cust.cd_gender,
        cust.cd_marital_status,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        sales.total_sales,
        sales.total_orders,
        ROW_NUMBER() OVER (PARTITION BY addr.ca_state ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        CustomerData cust
    JOIN 
        AddressData addr ON cust.c_customer_sk = addr.ca_address_sk
    LEFT JOIN 
        SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    total_orders,
    sales_rank
FROM 
    EnrichedCustomerData
WHERE 
    total_sales IS NOT NULL
ORDER BY 
    sales_rank, ca_state, total_sales DESC;
