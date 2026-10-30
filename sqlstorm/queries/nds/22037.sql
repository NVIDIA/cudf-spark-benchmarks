
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        sr_store_sk, sr_item_sk
)
SELECT 
    r.ss_store_sk,
    r.ss_item_sk,
    COALESCE(r.total_sales_quantity, 0) AS sales_quantity,
    COALESCE(c.total_return_quantity, 0) AS return_quantity,
    (COALESCE(r.total_net_paid, 0) - COALESCE(c.total_return_amount, 0)) AS net_income,
    r.sales_rank
FROM 
    RankedSales r
FULL OUTER JOIN 
    CustomerReturns c ON r.ss_store_sk = c.sr_store_sk AND r.ss_item_sk = c.sr_item_sk
WHERE 
    (r.sales_rank IS NOT NULL OR c.total_return_quantity IS NOT NULL) AND
    (r.total_sales_quantity - c.total_return_quantity) > 0
ORDER BY 
    net_income DESC, r.ss_store_sk, r.ss_item_sk;
