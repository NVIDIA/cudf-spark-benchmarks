
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM RankedCustomers rc
    WHERE rc.rnk <= 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(ss.total_sales, 0) AS total_sales,
    ss.order_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM TopCustomers tc
LEFT JOIN SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY total_sales DESC, tc.cd_gender, tc.c_last_name;
