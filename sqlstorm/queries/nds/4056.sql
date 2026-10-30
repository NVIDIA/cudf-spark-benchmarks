WITH CustomerRank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ReturnStats AS (
    SELECT 
        sr_customer_sk, 
        COUNT(*) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    ss.total_sales AS total_sales,
    ss.total_sales_amount AS total_sales_amount,
    cr.rank_gender
FROM 
    CustomerRank cr
LEFT JOIN 
    ReturnStats rs ON cr.c_customer_sk = rs.sr_customer_sk
LEFT JOIN 
    SalesStats ss ON cr.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cr.rank_gender = 1 
    AND (ss.total_sales IS NULL OR ss.total_sales > 5) 
ORDER BY 
    cr.cd_purchase_estimate DESC, 
    cr.c_last_name ASC;