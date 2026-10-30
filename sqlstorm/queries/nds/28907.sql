
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ai.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
), 
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
), 
RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cs_ext_sales_price DESC) AS rank
    FROM 
        SalesInfo
)
SELECT 
    cd_gender,
    COUNT(*) AS total_sales,
    AVG(cs_ext_sales_price) AS avg_sale_price,
    SUM(cs_sales_price) AS total_revenue,
    MAX(cs_ext_sales_price) AS max_sale_price
FROM 
    RankedSales
WHERE 
    rank <= 10
GROUP BY 
    cd_gender
ORDER BY 
    total_revenue DESC;
