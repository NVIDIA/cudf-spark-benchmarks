
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS TotalNetPaid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 2450000
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS TotalReturns,
        SUM(cr.cr_return_amount) AS TotalReturnAmount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450060
    GROUP BY cr.cr_item_sk
),
CombinedData AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ProfitRank,
        rs.TotalQuantity,
        rs.TotalNetPaid,
        COALESCE(fr.TotalReturns, 0) AS TotalReturns,
        COALESCE(fr.TotalReturnAmount, 0) AS TotalReturnAmount,
        CASE 
            WHEN rs.TotalNetPaid > 1000 THEN 'High Value'
            WHEN rs.TotalNetPaid BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS ValueCategory
    FROM RankedSales rs
    LEFT JOIN FilteredReturns fr ON rs.ws_item_sk = fr.cr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(cd.cd_dep_count / NULLIF(cd.cd_dep_college_count, 0), 0) AS DependentsToCollegeRatio,
    cd.cd_credit_rating,
    COUNT(cd.cd_demo_sk) OVER (PARTITION BY cd.cd_gender, cd.cd_credit_rating) AS GenderCreditCount
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN CombinedData cd_data ON cd_data.ws_item_sk = c.c_customer_sk
WHERE 
    (cd.cd_purchase_estimate > 1000 OR (cd.cd_gender = 'F' AND cd.cd_marital_status = 'S'))
    AND cd_data.TotalReturns > 0
    AND (cd_data.ValueCategory = 'High Value' OR cd_data.ValueCategory IS NULL)
ORDER BY cd_data.TotalNetPaid DESC
LIMIT 100;
