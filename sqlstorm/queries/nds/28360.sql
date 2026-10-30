
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerAggregate AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        COUNT(s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_net_profit
    FROM 
        customer AS c
    JOIN 
        AddressInfo AS a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        store_sales AS s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, a.full_address, a.ca_city, a.ca_state, a.ca_zip, d.cd_gender, d.cd_marital_status, d.cd_purchase_estimate, c.c_first_name, c.c_last_name
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    total_sales,
    total_net_profit,
    RANK() OVER (ORDER BY total_net_profit DESC) AS sales_rank
FROM 
    CustomerAggregate
WHERE 
    cd_purchase_estimate > 1000
ORDER BY 
    sales_rank
LIMIT 100;
