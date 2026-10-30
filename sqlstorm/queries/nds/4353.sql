
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.c_customer_sk,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE 
        td.t_hour BETWEEN 9 AND 17
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_bill_customer_sk
),
ReturnsData AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales,
    CASE 
        WHEN tc.cd_purchase_estimate < 100 THEN 'Low'
        WHEN tc.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_category
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    ReturnsData rd ON tc.c_customer_sk = rd.sr_customer_sk
WHERE 
    tc.cd_gender IS NOT NULL
ORDER BY 
    net_sales DESC;
