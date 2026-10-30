
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.marital_status,
        si.total_profit
    FROM 
        CustomerInfo ci
    JOIN 
        SalesCTE si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE 
        si.profit_rank <= 10
)

SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.marital_status,
    tc.ca_city,
    tc.ca_state,
    tc.ca_country,
    tc.total_profit,
    CASE 
        WHEN tc.cd_gender = 'F' THEN 'Female'
        WHEN tc.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender_description
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_profit DESC;
