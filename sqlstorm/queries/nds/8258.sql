
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, 
        cd.cd_credit_rating, hd.hd_income_band_sk
), DateSales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
), FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.total_quantity,
        cd.total_spent,
        ds.yearly_sales
    FROM 
        CustomerData cd
    LEFT JOIN 
        DateSales ds ON cd.hd_income_band_sk = ds.d_year
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 10000 THEN 'High Value'
        WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalReport
WHERE 
    total_quantity > 10 AND 
    cd_gender = 'F'
ORDER BY 
    total_spent DESC
LIMIT 100;
