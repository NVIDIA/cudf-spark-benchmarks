
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
                                        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
ProfitableCustomers AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           total_profit,
           RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM CustomerSales
),
CustomerDetails AS (
    SELECT pc.c_customer_sk, 
           pc.c_first_name, 
           pc.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM ProfitableCustomers pc
    JOIN customer_demographics cd ON pc.c_customer_sk = cd.cd_demo_sk
    WHERE pc.profit_rank <= 10
)
SELECT cd.c_first_name, 
       cd.c_last_name, 
       cd.cd_gender, 
       cd.cd_marital_status, 
       cd.cd_education_status, 
       pc.total_profit
FROM CustomerDetails cd
JOIN ProfitableCustomers pc ON cd.c_customer_sk = pc.c_customer_sk
ORDER BY total_profit DESC;
