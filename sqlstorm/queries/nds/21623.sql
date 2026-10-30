
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dc.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dc ON ws.ws_sold_date_sk = dc.d_date_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
        AND dc.d_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, dc.d_date
),
TopCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_sales DESC) AS customer_rank
    FROM 
        CustomerMetrics
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.total_sales,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent'
        WHEN tc.order_count BETWEEN 1 AND 5 THEN 'Occasional'
        ELSE 'Rare'
    END AS purchase_frequency,
    COALESCE(NULLIF(tc.total_sales / NULLIF(tc.order_count, 0), 0), 0) AS avg_sales_per_order,
    CASE 
        WHEN tc.total_sales = 0 THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    TopCustomers tc
WHERE 
    tc.customer_rank <= 10
    AND tc.cd_gender IS NOT NULL
ORDER BY 
    tc.total_sales DESC, 
    tc.c_customer_id;
