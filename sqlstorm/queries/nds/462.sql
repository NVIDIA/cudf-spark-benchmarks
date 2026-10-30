
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        COALESCE(NULLIF(cd.cd_gender, 'M'), 'NOT_SPECIFIED') AS gender_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.total_sales,
        cd.c_first_name,
        cd.c_last_name,
        cd.gender_status
    FROM RankedSales cs
    JOIN CustomerDetails cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
    WHERE sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_tax) AS total_tax,
    CASE 
        WHEN tc.total_sales > 5000 THEN 'High'
        WHEN tc.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM TopCustomers tc
LEFT JOIN web_sales ws ON tc.ws_bill_customer_sk = ws.ws_bill_customer_sk
GROUP BY tc.c_first_name, tc.c_last_name, tc.total_sales
ORDER BY total_sales DESC;
