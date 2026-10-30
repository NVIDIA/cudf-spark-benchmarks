
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS row_num
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
filtered_dates AS (
    SELECT 
        d.d_date,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year > 1998
    GROUP BY 
        d.d_date, d.d_year
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUBSTRING(cd.c_first_name, 1, 1) || ' ' || cd.c_last_name AS abbreviated_name,
    fd.d_date,
    fd.total_sales,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY fd.total_sales DESC) AS sales_rank
FROM 
    customer_data cd
LEFT JOIN 
    filtered_dates fd ON fd.d_year = (EXTRACT(YEAR FROM DATE '2002-10-01') - 1)
WHERE 
    cd.row_num = 1
AND 
    (cd.purchase_estimate > 1000 OR (cd.cd_gender = 'F' AND cd.cd_marital_status IS NULL))
GROUP BY 
    cd.c_customer_sk, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    fd.d_date, 
    fd.total_sales
ORDER BY 
    cd.cd_gender, sales_rank DESC
LIMIT 50;
