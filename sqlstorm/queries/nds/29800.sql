
WITH CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        LOWER(cd_education_status) AS education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.education_status,
        d.cd_gender,
        sd.total_sales,
        RANK() OVER (PARTITION BY a.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        CustomerAddress a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk AS customer_sk,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    c.full_address,
    c.education_status,
    c.cd_gender,
    c.total_sales
FROM 
    RankedCustomers c
WHERE 
    c.sales_rank <= 10
ORDER BY 
    c.full_address, 
    c.education_status;
