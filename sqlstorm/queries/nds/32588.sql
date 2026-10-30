
WITH  TotalReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    UNION ALL
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesData AS (
    SELECT 
        customer.c_customer_sk,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs_ext_sales_price), 0) AS total_catalog_sales
    FROM 
        customer
    LEFT JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales ON customer.c_customer_sk = catalog_sales.cs_bill_customer_sk
    GROUP BY 
        customer.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating,
        d.cd_purchase_estimate,
        rank() OVER (PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    SUM(sd.total_web_sales + sd.total_catalog_sales) AS total_sales,
    CASE 
        WHEN SUM(sd.total_web_sales + sd.total_catalog_sales) > 1000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS customer_value,
    ROW_NUMBER() OVER (ORDER BY SUM(sd.total_web_sales + sd.total_catalog_sales) DESC) AS sales_rank,
    NTILE(4) OVER (ORDER BY SUM(sd.total_web_sales + sd.total_catalog_sales)) AS sales_quartile,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount
FROM 
    CustomerDemographics AS cd
JOIN 
    SalesData AS sd ON cd.c_customer_sk = sd.c_customer_sk
LEFT JOIN 
    TotalReturns AS tr ON cd.c_customer_sk = tr.wr_returning_customer_sk
WHERE 
    cd.cd_credit_rating IS NOT NULL
GROUP BY 
    cd.c_customer_sk, tr.total_return_quantity, tr.total_return_amount
HAVING 
    SUM(sd.total_web_sales + sd.total_catalog_sales) > 500
ORDER BY 
    total_sales DESC;
