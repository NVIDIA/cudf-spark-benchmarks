
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        NULLIF(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) 
                               FROM date_dim d 
                               WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_bill_customer_sk
),
ReturnData AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk >= (SELECT MIN(d.d_date_sk) 
                                     FROM date_dim d 
                                     WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name || ' ' || cd.c_last_name AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    ReturnData rd ON cd.c_customer_sk = rd.sr_customer_sk
WHERE 
    cd.dep_count IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 100;
