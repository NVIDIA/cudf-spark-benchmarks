
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
customer_demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer_demographics cd
), 
sales_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_marital_status,
    r.r_reason_desc,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cs.order_count > 5
    AND cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    cd.cd_marital_status,
    r.r_reason_desc,
    cs.total_sales,
    cs.order_count
ORDER BY 
    cs.total_sales DESC;
