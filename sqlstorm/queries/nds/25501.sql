
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerPart AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopSellers AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    cp.full_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    ts.sales_rank,
    'Address: ' || cp.full_address || ', ' || cp.ca_city || ', ' || cp.ca_state || ' ' || cp.ca_zip AS formatted_address
FROM 
    CustomerPart cp
JOIN 
    TopSellers ts ON cp.c_customer_sk = ts.ws_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank, cp.full_name;
