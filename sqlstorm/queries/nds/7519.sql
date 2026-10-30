
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_sales,
        ci.order_count,
        RANK() OVER (ORDER BY ci.total_sales DESC) AS sales_rank
    FROM customer_info ci
),
frequent_reasons AS (
    SELECT 
        sr.sr_reason_sk, 
        r.r_reason_desc, 
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_reason_sk, r.r_reason_desc
),
top_reasons AS (
    SELECT 
        fr.r_reason_desc,
        fr.return_count,
        RANK() OVER (ORDER BY fr.return_count DESC) AS reason_rank
    FROM frequent_reasons fr
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tr.r_reason_desc,
    tr.return_count
FROM top_customers tc
JOIN top_reasons tr ON tc.order_count > 0
WHERE tc.sales_rank <= 10 AND tr.reason_rank <= 5
ORDER BY tc.total_sales DESC, tr.return_count DESC;
