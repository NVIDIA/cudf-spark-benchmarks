WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(ws_ext_sales_price) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
TopSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate,
        c.total_spent
    FROM 
        RankedCustomers c
    WHERE 
        c.rank_by_gender <= 10
),
SalesByDate AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    s.daily_sales,
    CASE 
        WHEN s.daily_sales > 500 THEN 'High Sales Day'
        WHEN s.daily_sales BETWEEN 200 AND 500 THEN 'Moderate Sales Day'
        ELSE 'Low Sales Day'
    END AS sales_category
FROM 
    TopSpenders t
JOIN 
    SalesByDate s ON DATE(s.d_date) = DATE(cast('2002-10-01' as date))
ORDER BY 
    t.total_spent DESC;