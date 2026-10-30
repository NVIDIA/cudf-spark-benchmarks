
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        RankedCustomers AS rc
    JOIN 
        web_sales AS ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.rank <= 10
    GROUP BY 
        rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.cd_gender, rc.cd_marital_status
),
SalesByMonth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        sales_year, sales_month
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    sbm.sales_year,
    sbm.sales_month,
    sbm.monthly_sales,
    DENSE_RANK() OVER (PARTITION BY sbm.sales_year ORDER BY sbm.monthly_sales DESC) AS sales_rank
FROM 
    TopCustomers AS tc
JOIN 
    SalesByMonth AS sbm ON tc.c_customer_sk = sbm.sales_year
ORDER BY 
    sbm.sales_year, sbm.sales_month, sales_rank;
