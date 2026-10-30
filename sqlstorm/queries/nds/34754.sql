
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
SalesWithDemographics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        s.total_sales,
        s.sales_rank
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        s.total_sales > (SELECT AVG(total_sales) FROM SalesCTE)
),
TopSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS overall_rank
    FROM 
        SalesWithDemographics
)
SELECT 
    t.c_customer_id AS customer_id,
    CONCAT(t.c_first_name, ' ', t.c_last_name) AS full_name,
    t.cd_gender AS gender,
    t.cd_marital_status AS marital_status,
    t.cd_purchase_estimate AS purchase_estimate,
    t.cd_credit_rating AS credit_rating,
    t.total_sales,
    CASE 
        WHEN t.sales_rank = 1 THEN 'Top'
        WHEN t.sales_rank <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS sales_category
FROM 
    TopSales t
WHERE 
    t.overall_rank <= 10
ORDER BY 
    t.total_sales DESC;
