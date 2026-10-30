
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_quantity) DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ss.ss_sold_date_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.ss_sold_date_sk,
    sh.total_quantity,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN COALESCE(rs.total_returned_quantity, 0) > 0
        THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    sales_hierarchy sh
LEFT JOIN 
    returns_summary rs ON sh.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    sh.rn = 1
ORDER BY 
    sh.total_quantity DESC
LIMIT 100;
