
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, cd.cd_gender
), HighValueCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count
    FROM 
        CustomerSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
), CustomerAddressDetails AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    hv.c_customer_id,
    hv.total_sales,
    hv.order_count,
    cad.ca_city,
    cad.ca_state,
    cad.ca_country
FROM 
    HighValueCustomers hv
JOIN 
    CustomerAddressDetails cad ON hv.c_customer_id = cad.c_customer_id
WHERE 
    cad.total_orders > 1
ORDER BY 
    hv.total_sales DESC
LIMIT 10;
