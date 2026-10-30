
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) as rnk
    FROM store_returns
    GROUP BY sr_item_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk, 
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING COUNT(*) > 100
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(sr.returned_amount), 0) AS total_return_amount,
        pi.total_sales,
        pi.total_profit
    FROM item i
    LEFT JOIN (
        SELECT 
            sr_item_sk,
            SUM(sr_return_amt_inc_tax) AS returned_amount
        FROM store_returns
        GROUP BY sr_item_sk
    ) sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN PopularItems pi ON i.i_item_sk = pi.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, pi.total_sales, pi.total_profit
),
ItemIncomeCategories AS (
    SELECT 
        i.i_item_sk,
        CASE 
            WHEN LOWER(cd.cd_credit_rating) = 'good' THEN 'High Value'
            ELSE 'Low Value'
        END AS value_category
    FROM item i
    JOIN customer c ON i.i_item_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_return_amount,
    id.total_sales,
    id.total_profit,
    COALESCE(value_category, 'Unknown') AS income_band
FROM ItemDetails id
LEFT JOIN ItemIncomeCategories ic ON id.i_item_sk = ic.i_item_sk
WHERE id.total_return_amount > 100
AND id.total_sales IS NOT NULL
ORDER BY id.total_sales DESC, id.total_return_amount ASC
LIMIT 50;
