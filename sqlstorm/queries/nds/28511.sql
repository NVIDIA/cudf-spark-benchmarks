
WITH Ranked_Addresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_country LIKE '%United%'
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
    WHERE 
        cd_education_status IN ('PhD', 'Masters') 
),
Sales_Aggregates AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    cd.gender_marital_status, 
    sa.total_sales,
    sa.order_count
FROM 
    Ranked_Addresses ca
JOIN 
    Customer_Demographics cd ON cd.cd_demo_sk = ca.ca_address_sk
JOIN 
    Sales_Aggregates sa ON sa.ws_bill_addr_sk = ca.ca_address_sk
WHERE 
    ca.city_rank <= 10
ORDER BY 
    sa.total_sales DESC, 
    ca.ca_city, 
    ca.ca_state;
