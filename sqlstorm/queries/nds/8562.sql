
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_ship_date_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        r.sales_rank <= 10
),
SalesAnalysis AS (
    SELECT 
        tc.cd_gender,
        tc.cd_marital_status,
        AVG(tc.total_sales) AS avg_sales,
        COUNT(tc.ws_bill_customer_sk) AS customer_count
    FROM 
        TopCustomers tc
    GROUP BY 
        tc.cd_gender, 
        tc.cd_marital_status
)
SELECT 
    sa.cd_gender,
    sa.cd_marital_status,
    sa.avg_sales,
    sa.customer_count,
    CASE 
        WHEN sa.avg_sales > 1000 THEN 'High Spenders'
        WHEN sa.avg_sales BETWEEN 500 AND 1000 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END AS spending_category
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.avg_sales DESC;
