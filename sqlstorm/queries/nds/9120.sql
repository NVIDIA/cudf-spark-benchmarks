
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 500 AND 
        ca.ca_state IN ('CA', 'TX')
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerData
)
SELECT 
    ca_city,
    ca_state,
    COUNT(c_customer_id) AS num_customers,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM 
    RankedCustomers
WHERE 
    sales_rank <= 10
GROUP BY 
    ca_city, ca_state
ORDER BY 
    ca_state, num_customers DESC;
