
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_paid) AS total_web_sales_amount
    FROM 
        customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_web_sales_amount
    FROM 
        CustomerStats AS cs
    JOIN customer AS c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY 
        cs.total_web_sales_amount DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_web_sales_amount,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_net_profit ELSE 0 END) AS total_profit_last_year
FROM 
    TopCustomers AS tc
LEFT JOIN 
    web_sales AS ws ON tc.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_web_sales, tc.total_web_sales_amount
ORDER BY 
    total_profit_last_year DESC;
