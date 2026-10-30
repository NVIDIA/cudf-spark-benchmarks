
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2420 AND 2425
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    WHERE cs.total_sales > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
CustomerAndDemographics AS (
    SELECT 
        hvc.*,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM HighValueCustomers hvc
    LEFT JOIN customer c ON hvc.c_customer_sk = c.c_customer_sk
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cad.c_customer_sk,
    cad.c_first_name,
    cad.c_last_name,
    cad.total_sales,
    cad.total_orders,
    cad.cd_gender,
    cad.cd_marital_status,
    cad.cd_purchase_estimate
FROM CustomerAndDemographics cad
WHERE CAD.total_orders > 3 
  AND (cad.cd_gender = 'M' OR (cad.cd_gender IS NULL AND cad.cd_marital_status = 'M'))
ORDER BY cad.total_sales DESC;
