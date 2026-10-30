
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.profit_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_credit_rating = 'Excellent' THEN 'High Value'
            WHEN cd.cd_credit_rating = 'Good' THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        customer_demographics AS cd
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_value,
    ROW_NUMBER() OVER (PARTITION BY cd.customer_value ORDER BY tc.total_profit DESC) AS customer_rank
FROM 
    TopCustomers AS tc
LEFT JOIN 
    customer AS c ON tc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_demo_sk IS NOT NULL
ORDER BY 
    customer_value, total_profit DESC
;
