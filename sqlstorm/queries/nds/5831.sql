
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM RankedCustomers rc
    WHERE rc.rank <= 5
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_quantity) as total_quantity,
        SUM(ws.ws_sales_price) as total_sales,
        ws.ws_ship_date_sk,
        c.c_customer_sk
    FROM web_sales ws
    JOIN TopCustomers c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ws.ws_ship_date_sk, c.c_customer_sk
)
SELECT 
    d.d_date,
    ts.c_customer_sk,
    MAX(ts.total_quantity) AS max_quantity,
    AVG(ts.total_sales) AS avg_sales
FROM date_dim d
JOIN SalesSummary ts ON d.d_date_sk = ts.ws_ship_date_sk
WHERE d.d_year = 2023
GROUP BY d.d_date, ts.c_customer_sk
ORDER BY d.d_date ASC, max_quantity DESC;
