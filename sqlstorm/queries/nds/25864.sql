
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerOverview AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ReturnData AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
CompleteData AS (
    SELECT 
        co.c_customer_sk,
        co.full_name,
        co.cd_gender,
        co.cd_marital_status,
        co.cd_purchase_estimate,
        co.cd_credit_rating,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_revenue
    FROM 
        CustomerOverview co
    LEFT JOIN 
        AddressDetails ad ON ad.ca_address_sk = co.c_customer_sk
    LEFT JOIN 
        SalesData sd ON sd.ws_bill_customer_sk = co.c_customer_sk
    LEFT JOIN 
        ReturnData rd ON rd.wr_returning_customer_sk = co.c_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    SUM(total_sales) AS total_sales,
    SUM(total_returns) AS total_returns,
    AVG(CASE WHEN total_sales > 0 THEN total_returns / total_sales ELSE 0 END) AS return_ratio
FROM 
    CompleteData
GROUP BY 
    full_name, ca_city, ca_state
ORDER BY 
    total_sales DESC, return_ratio ASC
LIMIT 10;
