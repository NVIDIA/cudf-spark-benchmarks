
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(ts.total_sales, 0) AS total_sales,
    CASE 
        WHEN ts.total_sales > 0 THEN ROUND((COALESCE(cr.total_returns, 0) / ts.total_sales) * 100, 2)
        ELSE 0 
    END AS return_percentage,
    d.cd_gender,
    d.cd_marital_status
FROM 
    CustomerReturns cr
FULL OUTER JOIN 
    TotalSales ts ON cr.c_customer_sk = ts.customer_sk
INNER JOIN 
    customer AS c ON c.c_customer_sk = COALESCE(cr.c_customer_sk, ts.customer_sk)
INNER JOIN 
    Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    (d.cd_purchase_estimate > 500 AND d.cd_credit_rating = 'Good') OR 
    (d.cd_dep_count IS NULL OR d.cd_gender = 'F')
ORDER BY 
    return_percentage DESC, total_sales DESC
LIMIT 100;
