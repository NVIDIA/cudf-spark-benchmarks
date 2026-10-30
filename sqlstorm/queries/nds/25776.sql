
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
CompetitorAnalysis AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.full_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        ci.ca_country,
        ss.total_orders,
        ss.total_spent,
        RANK() OVER (ORDER BY ss.total_spent DESC) AS spending_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesSummary ss ON ci.c_customer_id = ss.c_customer_id
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_spent, 0) AS total_spent,
    spending_rank
FROM 
    CompetitorAnalysis
WHERE 
    spending_rank <= 100
ORDER BY 
    total_spent DESC, full_name ASC;
