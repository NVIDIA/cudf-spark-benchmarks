
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452000 AND 2452060
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate) FROM customer_demographics
        )
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    SUM(COALESCE(rs.total_quantity, 0)) AS web_sales_quantity,
    SUM(COALESCE(rs.total_net_paid, 0)) AS web_sales_amount,
    COALESCE(r.total_returns, 0) AS store_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amount
FROM 
    customer cu
LEFT JOIN 
    RankedSales rs ON cu.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    ReturnStats r ON cu.c_customer_sk = r.sr_customer_sk
WHERE 
    cu.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM HighValueCustomers)
    AND (cu.c_birth_year < 1975 OR cu.c_first_name LIKE 'A%')
GROUP BY 
    cu.c_customer_id, cu.c_first_name, cu.c_last_name, r.total_returns, r.total_return_amt
HAVING 
    SUM(COALESCE(rs.total_net_paid, 0)) > 1000
ORDER BY 
    web_sales_amount DESC
LIMIT 50;
