
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        COALESCE(NULLIF(cd.cd_credit_rating, 'poor'), 'unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000) 
        OR (cd.cd_gender = 'M' AND cd.cd_purchase_estimate IS NULL)
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.credit_rating,
    COALESCE(rr.total_returned_quantity, 0) AS total_returns,
    ss.total_sales_price,
    ss.order_count
FROM 
    CustomerSummary cs
LEFT JOIN 
    RankedReturns rr ON rr.sr_item_sk = cs.c_customer_sk  
LEFT JOIN 
    SalesSummary ss ON ss.ws_item_sk = cs.c_customer_sk  
WHERE 
    (COALESCE(rr.total_returned_quantity, 0) IS NOT NULL OR ss.total_sales_price IS NOT NULL)
    AND (cs.credit_rating IS NOT NULL AND cs.credit_rating != 'unknown')
ORDER BY 
    cs.c_last_name ASC,
    total_returns DESC;
