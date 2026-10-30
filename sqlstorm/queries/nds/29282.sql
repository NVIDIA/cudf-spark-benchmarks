
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) as total_sales,
        COUNT(ws_order_number) as order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        cu.c_email_address,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        cu.cd_credit_rating,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_sales DESC) as sales_rank
    FROM 
        CustomerDetails cu
    LEFT JOIN 
        SalesData sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    addr.full_address,
    addr.location,
    addr.ca_country,
    rc.c_first_name,
    rc.c_last_name,
    rc.c_email_address,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_sales,
    rc.order_count
FROM 
    AddressDetails addr
JOIN 
    customer c ON addr.ca_address_sk = c.c_current_addr_sk
JOIN 
    RankedCustomers rc ON c.c_customer_sk = rc.c_customer_sk
WHERE 
    rc.sales_rank <= 100
ORDER BY 
    rc.sales_rank;
