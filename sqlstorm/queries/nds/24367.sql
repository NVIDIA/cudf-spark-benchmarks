
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20221231
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(cd.cd_purchase_estimate) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
AggregateSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_orders,
        sd.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_purchase_estimate,
        COALESCE(CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single' END, 'Unknown') AS marital_status,
        DENSE_RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM SalesData sd
    JOIN CustomerDemographics cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    a.ws_bill_customer_sk,
    a.total_orders,
    a.total_profit,
    a.cd_gender,
    a.marital_status,
    a.total_purchase_estimate,
    a.profit_rank
FROM AggregateSales a
WHERE a.total_profit > (
    SELECT AVG(total_profit) 
    FROM AggregateSales
)
OR EXISTS (
    SELECT 1 
    FROM store_sales ss 
    WHERE ss.ss_customer_sk = a.ws_bill_customer_sk 
    AND ss_ext_sales_price IS NOT NULL 
    AND ss_ext_tax IS NULL
)
ORDER BY a.total_profit DESC, a.total_orders DESC
LIMIT 5 OFFSET 10;
