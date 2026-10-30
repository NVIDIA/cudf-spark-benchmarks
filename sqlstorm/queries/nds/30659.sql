
WITH  SalesTrend AS (
    SELECT 
        d.d_year, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws_ext_sales_price) > 0
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_returned
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ct.cd_gender,
    ct.customer_count,
    COALESCE(st.total_sales, 0) AS total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_returned, 0) AS total_returned,
    CASE
        WHEN ct.customer_count > 0 THEN ROUND((COALESCE(st.total_sales, 0) - COALESCE(cr.total_returned, 0)) / ct.customer_count, 2)
        ELSE 0
    END AS avg_net_sales_per_customer
FROM 
    CustomerDemographics ct
LEFT JOIN 
    (SELECT 
        d_year, 
        SUM(ws_ext_sales_price) AS total_sales 
     FROM 
        date_dim d 
     JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
     WHERE 
        d.d_year >= 2020
     GROUP BY 
        d_year) st ON st.d_year = 2021
LEFT JOIN 
    CustomerReturns cr ON cr.c_customer_sk = ct.customer_count
ORDER BY 
    ct.cd_gender;
