
WITH parsed_address AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LEFT(ca_city, 3) AS city_prefix,
        UPPER(ca_state) AS state_upper
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUBSTRING(cd.cd_credit_rating, 1, 3) AS credit_rating_short
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        CASE 
            WHEN ws_quantity + cs_quantity + ss_quantity IS NULL THEN 0 
            ELSE COALESCE(ws_quantity, 0) + COALESCE(cs_quantity, 0) + COALESCE(ss_quantity, 0) 
        END AS total_quantity,
        ws_bill_customer_sk AS customer_sk,
        ws_sold_date_sk
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
),
final_results AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        pa.full_address,
        si.total_quantity,
        si.ws_sold_date_sk
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.customer_sk
    JOIN 
        parsed_address pa ON ci.c_customer_sk = pa.ca_address_sk
)
SELECT 
    full_name,
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    cd_education_status AS education,
    full_address,
    SUM(total_quantity) AS overall_quantity,
    COUNT(DISTINCT ws_sold_date_sk) AS selling_days
FROM 
    final_results
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, full_address
ORDER BY 
    overall_quantity DESC
LIMIT 100;
