
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_quantity,
        cp.total_sales
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cp.total_sales > 1000 AND 
        cd.cd_marital_status = 'M'
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_address_sk AS c_customer_sk
    FROM 
        customer_address ca
    JOIN 
        HighValueCustomers hvc ON hvc.c_customer_sk = ca.ca_address_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    ca.ca_city,
    ca.ca_state,
    hvc.total_quantity,
    hvc.total_sales
FROM 
    HighValueCustomers hvc
JOIN 
    CustomerAddresses ca ON hvc.c_customer_sk = ca.c_customer_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;
