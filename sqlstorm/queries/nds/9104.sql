
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_items,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_ship_customer_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
StoreSalesData AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_sales_price) AS total_sales_amount
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
CombinedSalesReturns AS (
    SELECT 
        COALESCE(ws.ws_ship_customer_sk, ss.ss_customer_sk) AS customer_sk,
        COALESCE(ws.total_quantity_sold, 0) + COALESCE(ss.total_quantity_sold, 0) AS total_sales_quantity,
        COALESCE(ws.total_sales_amount, 0) + COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(cr.total_returned_items, 0) AS total_returned_items,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(cr.return_count, 0) AS total_return_count
    FROM 
        WebSalesData ws
    FULL OUTER JOIN 
        StoreSalesData ss ON ws.ws_ship_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON COALESCE(ws.ws_ship_customer_sk, ss.ss_customer_sk) = cr.cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        cs.customer_sk,
        cs.total_sales_quantity,
        cs.total_sales_amount,
        cs.total_returned_items,
        cs.total_returned_amount,
        cs.total_return_count
    FROM 
        CombinedSalesReturns cs
    JOIN 
        customer c ON cs.customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.gender,
    cd.marital_status,
    cd.education_status,
    COUNT(DISTINCT cd.customer_sk) AS total_customers,
    SUM(cd.total_sales_quantity) AS overall_quantity_sold,
    SUM(cd.total_sales_amount) AS overall_sales_amount,
    SUM(cd.total_returned_items) AS total_returned_items,
    SUM(cd.total_returned_amount) AS total_returned_amount
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.gender, cd.marital_status, cd.education_status
ORDER BY 
    overall_sales_amount DESC
LIMIT 10;
