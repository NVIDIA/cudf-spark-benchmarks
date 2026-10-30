
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_item_sk
), 
HighReturnCustomers AS (
    SELECT 
        DISTINCT c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ra.total_returned
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RankedReturns ra ON c.c_customer_sk = ra.sr_customer_sk
    WHERE 
        ra.return_rank = 1 AND cd.cd_purchase_estimate IS NOT NULL
), 
StoreSalesWithReturns AS (
    SELECT 
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COALESCE(SUM(rr.total_returned), 0) AS total_returns
    FROM 
        store_sales ss
    LEFT JOIN 
        RankedReturns rr ON ss.ss_item_sk = rr.sr_item_sk
    GROUP BY 
        ss.ss_store_sk, ss.ss_item_sk
), 
SalesReturnRatio AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        CASE 
            WHEN s.total_returns = 0 THEN NULL
            ELSE s.total_sales / NULLIF(s.total_returns, 0)
        END AS sales_to_return_ratio
    FROM 
        StoreSalesWithReturns s
    WHERE 
        s.total_sales > 0
)
SELECT 
    s.ss_store_sk,
    SUM(s.sales_to_return_ratio) / COUNT(*) AS avg_sales_return_ratio,
    ROW_NUMBER() OVER (ORDER BY SUM(s.sales_to_return_ratio) DESC) AS store_rank
FROM 
    SalesReturnRatio s
GROUP BY 
    s.ss_store_sk
HAVING 
    AVG(s.sales_to_return_ratio) IS NOT NULL
ORDER BY 
    avg_sales_return_ratio DESC;
