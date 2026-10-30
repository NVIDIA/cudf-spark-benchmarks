
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ad.ca_city AS address_city, 
        ad.ca_state AS address_state, 
        ad.ca_country AS address_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesSummary AS (
    SELECT 
        cd.full_name, 
        cd.address_city, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.full_name, 
        cd.address_city
),
TopSales AS (
    SELECT 
        full_name, 
        address_city, 
        total_sales, 
        order_count, 
        RANK() OVER (PARTITION BY address_city ORDER BY total_sales DESC) AS city_rank
    FROM 
        SalesSummary
)

SELECT 
    full_name, 
    address_city, 
    total_sales, 
    order_count
FROM 
    TopSales
WHERE 
    city_rank <= 5
ORDER BY 
    address_city, 
    total_sales DESC
