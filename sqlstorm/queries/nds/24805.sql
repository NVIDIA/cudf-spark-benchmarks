WITH  CustomerReturns AS (
    SELECT sr_customer_sk, 
           SUM(sr_return_quantity) AS total_returned,
           SUM(sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           COALESCE(SUM(ws_ext_sales_price), 0) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COALESCE(SUM(ws_ext_sales_price), 0) > 1000 AND COUNT(cr.sr_customer_sk) > 0
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status,
           CASE 
               WHEN cd.cd_gender = 'F' THEN 'Females' 
               ELSE 'Males' 
           END AS gender_desc
    FROM customer_demographics cd
    WHERE cd.cd_marital_status IN ('M', 'S')
),
CombinedData AS (
    SELECT hvc.c_customer_sk, 
           hvc.c_first_name,
           hvc.c_last_name,
           hvc.total_spent,
           cd.gender_desc
    FROM HighValueCustomers hvc
    JOIN CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
),
RankedCustomers AS (
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c.gender_desc ORDER BY c.total_spent DESC) AS sales_rank
    FROM CombinedData c
)
SELECT rc.gender_desc, 
       rc.c_first_name, 
       rc.c_last_name, 
       rc.total_spent, 
       rc.sales_rank
FROM RankedCustomers rc
WHERE rc.sales_rank <= 10
ORDER BY rc.gender_desc, rc.total_spent DESC;