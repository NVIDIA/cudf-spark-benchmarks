
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalResult AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        sd.total_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    COALESCE(f.total_sales, 0) AS total_sales
FROM 
    FinalResult f
ORDER BY 
    f.total_sales DESC;
