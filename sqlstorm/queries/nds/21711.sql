
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws.ws_item_sk
),
HighValueReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > (SELECT AVG(sr2.sr_return_quantity) FROM store_returns sr2)
    GROUP BY 
        sr.sr_item_sk
),
CombinedData AS (
    SELECT 
        it.i_item_sk,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rv.return_count, 0) AS return_count,
        COALESCE(rv.total_return_amt, 0) AS total_return_amt
    FROM 
        item it
    LEFT JOIN RankedSales rs ON it.i_item_sk = rs.ws_item_sk
    LEFT JOIN HighValueReturns rv ON it.i_item_sk = rv.sr_item_sk
)
SELECT 
    c.c_customer_id, 
    DENSE_RANK() OVER (ORDER BY SUM(cd.cd_dep_count) DESC) AS demographic_rank,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    MAX(cd.cd_credit_rating) AS max_credit_rating,
    CASE WHEN AVG(cd.cd_purchase_estimate) > 1000 THEN 'High' ELSE 'Low' END AS purchase_category,
    SUM(cd.cd_dep_count) FILTER (WHERE cd.cd_gender = 'M') AS male_dependents,
    SUM(cd.cd_dep_count) FILTER (WHERE cd.cd_gender = 'F') AS female_dependents,
    CURRENT_DATE AS query_date
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CombinedData com ON com.i_item_sk = cd.cd_demo_sk
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(cd.cd_dep_count) > COALESCE(NULLIF((SELECT AVG(cd2.cd_dep_count) FROM customer_demographics cd2), 0), 1)
ORDER BY 
    demographic_rank ASC
LIMIT 50;
