
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        NULLIF(cd.cd_credit_rating, '') AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
),
AggregatedSales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.marital_status,
        ci.credit_rating,
        ds.d_year,
        SUM(sc.total_sales) AS total_spent
    FROM 
        CustomerInfo ci
    JOIN 
        SalesCTE sc ON ci.c_customer_sk = sc.ws_item_sk
    JOIN 
        DateInfo ds ON ds.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.marital_status, ci.credit_rating, ds.d_year
)
SELECT 
    asales.c_customer_sk, 
    asales.c_first_name, 
    asales.c_last_name, 
    asales.marital_status, 
    asales.credit_rating, 
    COALESCE(asales.total_spent, 0) AS total_spending,
    CASE 
        WHEN asales.total_spent IS NULL THEN 'No Purchases Made'
        ELSE 'Purchases Made'
    END AS purchase_status
FROM 
    AggregatedSales asales
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = asales.c_customer_sk
WHERE 
    asales.total_spent > (SELECT AVG(total_spent) FROM AggregatedSales) 
    OR asales.marital_status = 'Married'
ORDER BY 
    asales.total_spent DESC
LIMIT 10;
