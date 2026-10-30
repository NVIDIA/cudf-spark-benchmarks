
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        RankedReturns
    WHERE 
        rn <= 3
    GROUP BY 
        sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM 
        warehouse AS w
    WHERE 
        w.w_warehouse_sq_ft > 1000
),
ReturnsWithShipping AS (
    SELECT 
        rr.sr_item_sk,
        rr.sr_return_quantity,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        cd.cd_gender,
        cd.purchase_estimate
    FROM 
        RankedReturns AS rr
    JOIN 
        WarehouseInfo AS w ON rr.sr_item_sk = w.w_warehouse_sk
    LEFT JOIN 
        CustomerDemographics AS cd ON rr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    rws.sr_item_sk,
    SUM(rws.sr_return_quantity) AS total_returns,
    AVG(rws.purchase_estimate) AS avg_purchase_estimate,
    COUNT(CASE WHEN rws.cd_gender = 'M' THEN 1 END) AS male_return_count,
    COUNT(CASE WHEN rws.cd_gender = 'F' THEN 1 END) AS female_return_count,
    CASE 
        WHEN SUM(rws.sr_return_quantity) IS NULL THEN 'No Returns' 
        ELSE 'Returns Available' 
    END AS return_status
FROM 
    ReturnsWithShipping AS rws
GROUP BY 
    rws.sr_item_sk
HAVING 
    SUM(rws.sr_return_quantity) > 10 OR 
    (COUNT(*) > 5 AND AVG(rws.purchase_estimate) > 100)
ORDER BY 
    total_returns DESC
LIMIT 10 OFFSET 5;
