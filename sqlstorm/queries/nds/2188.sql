
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        wd.total_returns,
        ws.total_sales
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns AS wd ON c.c_customer_sk = wd.cr_returning_customer_sk
    LEFT JOIN 
        WebSalesSummary AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.total_returns, 0) AS total_returns,
    COALESCE(cd.total_sales, 0) AS total_sales,
    CASE 
        WHEN cd.total_returns > 0 THEN 'Returns'
        WHEN cd.total_sales > 0 THEN 'Sales'
        ELSE 'No Activity'
    END AS activity_type,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.total_sales, 0) DESC) AS sales_rank
FROM 
    CustomerDemographics AS cd
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.total_sales DESC;
