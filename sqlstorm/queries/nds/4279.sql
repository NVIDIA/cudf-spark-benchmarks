
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_total,
        COALESCE(SUM(sr.sr_return_amt), 0) AS store_return_total
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    sd.total_sales,
    cr.web_return_total,
    cr.store_return_total,
    CASE 
        WHEN cr.web_return_total > 0 OR cr.store_return_total > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    RankedCustomers rc
JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_item_sk
JOIN 
    CustomerReturns cr ON rc.c_customer_sk = cr.c_customer_sk
WHERE 
    rc.rn = 1 
    AND (sd.total_sales IS NOT NULL AND sd.total_sales > 1000)
    AND (cr.web_return_total > 50 OR cr.store_return_total > 50)
ORDER BY 
    rc.cd_gender, rc.cd_marital_status, sd.total_sales DESC
LIMIT 100;
