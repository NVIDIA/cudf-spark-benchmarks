
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' 
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' 
            ELSE '' 
        END || c.c_first_name AS full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        cd.full_name,
        cd.full_address,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    r.full_name,
    r.full_address,
    COALESCE(r.total_sales, 0.00) AS total_sales,
    r.sales_rank
FROM 
    RankedCustomers r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
