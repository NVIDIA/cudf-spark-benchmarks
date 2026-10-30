
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        cd.cd_purchase_estimate AS purchase_estimate,
        cd.cd_credit_rating AS credit_rating,
        cd.cd_dep_count AS dep_count,
        cd.cd_dep_employed_count AS dep_employed_count
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS number_of_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages_visited
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.gender,
        ci.marital_status,
        ci.education_status,
        ci.purchase_estimate,
        ci.credit_rating,
        ci.dep_count,
        ci.dep_employed_count,
        sd.total_spent,
        sd.number_of_orders,
        sd.distinct_pages_visited,
        RANK() OVER (ORDER BY sd.total_spent DESC) AS spending_rank
    FROM 
        CustomerInfo ci
        LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.customer_sk
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    gender, 
    marital_status, 
    education_status, 
    purchase_estimate, 
    credit_rating, 
    dep_count, 
    dep_employed_count, 
    total_spent, 
    number_of_orders, 
    distinct_pages_visited,
    spending_rank
FROM 
    RankedCustomers
WHERE 
    spending_rank <= 100
ORDER BY 
    spending_rank;
