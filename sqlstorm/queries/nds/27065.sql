
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        RANK() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA' 
        AND ca_zip LIKE '9%'
),
CustomerProfile AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year,
        d.d_month_seq,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_purchase_estimate,
        addr.full_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
    JOIN 
        RankedAddresses AS addr ON c.c_current_addr_sk = addr.ca_address_sk
    JOIN 
        date_dim AS d ON c.c_first_shipto_date_sk = d.d_date_sk
)
SELECT 
    cp.full_name,
    cp.cd_gender,
    cp.cd_marital_status,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM 
    CustomerProfile AS cp
JOIN 
    web_sales AS ws ON cp.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cp.full_name, cp.cd_gender, cp.cd_marital_status, cp.d_year
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000 AND cp.d_year = 2022
ORDER BY 
    total_sales DESC
LIMIT 10;
