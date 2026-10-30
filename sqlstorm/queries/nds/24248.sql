
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(r.total_return_amount, 0) AS total_returns,
        COALESCE(s.total_sales, 0) AS total_sales,
        hs.c_customer_sk,
        hs.customer_rank
    FROM 
        item i
    LEFT JOIN 
        (SELECT * FROM RankedSales WHERE rank_sales = 1) s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        SalesReturns r ON i.i_item_sk = r.sr_item_sk
    LEFT JOIN 
        HighValueCustomers hs ON hs.customer_rank <= 10
)
SELECT 
    i.i_item_id,
    i.total_sales, 
    i.total_returns,
    COALESCE(CASE WHEN i.total_sales IS NOT NULL AND i.total_returns IS NOT NULL 
        THEN i.total_sales - i.total_returns ELSE NULL END, 0) AS net_sales,
    i.customer_rank
FROM 
    ItemSummary i
WHERE 
    (i.total_sales IS NOT NULL AND i.total_sales > 1000)
    OR (i.total_returns IS NOT NULL AND i.total_returns > 100)
ORDER BY 
    net_sales DESC
LIMIT 100;
