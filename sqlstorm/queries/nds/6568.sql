
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cd_gender, cd_marital_status
),
TopCustomers AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        total_quantity,
        total_spent,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerStats
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_spent
FROM 
    TopCustomers
WHERE 
    rank <= 5
ORDER BY 
    cd_gender, total_spent DESC;
