
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    COUNT(*) AS total_purchases
FROM 
    RankedCustomers
WHERE 
    rnk = 1
GROUP BY 
    full_name, cd_gender, cd_marital_status
ORDER BY 
    max_purchase_estimate DESC
LIMIT 50;
