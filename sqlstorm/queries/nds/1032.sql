
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        DENSE_RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS return_rank
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, wr_item_sk
),
TopReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        total_returned_quantity
    FROM 
        RankedReturns
    WHERE 
        return_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(ss.sales), 0) AS total_store_sales,
    COALESCE(SUM(ws.sales), 0) AS total_web_sales,
    COUNT(DISTINCT tr.wr_item_sk) AS unique_returned_items
FROM 
    CustomerDemographics cd
LEFT JOIN (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS sales
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
) ss ON cd.c_customer_sk = ss.ss_customer_sk
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
) ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN TopReturns tr ON cd.c_customer_sk = tr.wr_returning_customer_sk
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT tr.wr_item_sk) > 0 OR COALESCE(SUM(ss.sales), 0) > 1000
ORDER BY 
    total_store_sales DESC, total_web_sales DESC;
