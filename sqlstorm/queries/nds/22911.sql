
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighValueReturns AS (
    SELECT 
        rr.sr_item_sk, 
        rr.return_count, 
        rr.total_return_amt,
        RANK() OVER (ORDER BY rr.total_return_amt DESC) AS rank_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_count > 5 OR rr.total_return_amt > 100
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 0
            ELSE cd_purchase_estimate / NULLIF(cd_dep_count, 0)
        END AS purchase_per_dependency,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM 
        customer_demographics
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(i_size, 'N/A') AS item_size,
        COALESCE(i_color, 'N/A') AS item_color
    FROM 
        item
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    ii.i_item_sk,
    ii.i_item_desc,
    ii.i_current_price,
    COALESCE(hvr.return_count, 0) AS return_count,
    COALESCE(hvr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN hvr.return_count IS NULL THEN 'No Returns'
        WHEN hvr.return_count > 10 THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_category,
    cd.purchase_per_dependency
FROM 
    CustomerDemographics cd
JOIN 
    HighValueReturns hvr ON cd.cd_demo_sk = hvr.sr_item_sk
RIGHT JOIN 
    ItemDetails ii ON hvr.sr_item_sk = ii.i_item_sk
WHERE 
    cd.gender_purchase_rank <= 5
ORDER BY 
    cd.cd_demo_sk, ii.i_item_desc;
