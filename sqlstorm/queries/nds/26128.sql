
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER(PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND cd.cd_gender = 'F'
),
RecentPurchases AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    COALESCE(rp.total_spent, 0) AS total_spent,
    COALESCE(rp.purchase_count, 0) AS purchase_count,
    cd.customer_rank
FROM 
    CustomerData cd
LEFT JOIN 
    RecentPurchases rp ON cd.c_customer_sk = rp.ws_bill_customer_sk
WHERE 
    cd.customer_rank <= 10
ORDER BY 
    cd.ca_state, total_spent DESC;
