
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighProfitCustomers AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name,
        cd.ca_city,
        rs.total_net_profit
    FROM 
        CustomerDetails cd 
    JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.profit_rank = 1
)

SELECT 
    hpc.c_customer_sk, 
    hpc.c_first_name, 
    hpc.c_last_name, 
    hpc.ca_city, 
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
    CASE
        WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value'
        WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    HighProfitCustomers hpc
LEFT JOIN 
    web_sales ws ON hpc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    hpc.c_customer_sk, 
    hpc.c_first_name, 
    hpc.c_last_name, 
    hpc.ca_city
ORDER BY 
    total_net_paid DESC
LIMIT 10;
