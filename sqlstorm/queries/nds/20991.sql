
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(COALESCE(sr_return_amt, 0)) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DailySales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_tax,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
ReturnsSummary AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_return_quantity) AS total_catalog_returns,
        SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return_amt
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(RR.total_returns, 0) AS total_returns,
    COALESCE(RR.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN COALESCE(RR.total_returns, 0) > 5 THEN 'Frequent Returner'
        ELSE 'Infrequent Returner'
    END AS returner_type,
    ds.sale_date,
    ds.total_sales,
    ds.total_sales_tax
FROM 
    CustomerDetails AS cd
LEFT JOIN 
    RankedReturns AS RR ON cd.c_customer_sk = RR.sr_customer_sk
JOIN 
    DailySales AS ds ON ds.sales_rank = 1
WHERE 
    cd.cd_gender IS NOT NULL 
    AND cd.cd_marital_status IS NOT NULL 
    AND (cd.cd_purchase_estimate > 1000 OR COALESCE(RR.total_return_amt, 0) > 50)
ORDER BY 
    ds.total_sales DESC, 
    cd.c_last_name ASC,
    cd.c_first_name ASC
LIMIT 50;
