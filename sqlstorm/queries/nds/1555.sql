
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnData AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return, 0) AS total_return,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return, 0)) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return, 0)) DESC) AS sales_rank
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    ReturnData rd ON cd.c_customer_sk = rd.customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    net_sales DESC
LIMIT 100;
