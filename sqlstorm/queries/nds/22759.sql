
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        COALESCE(cd_purchase_estimate, 0) AS purchase_estimate,
        DENSE_RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer_demographics
),
ItemDetails AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price,
        i_brand,
        COALESCE(i_size, 'N/A') AS item_size
    FROM 
        item
    WHERE 
        i_rec_end_date IS NULL OR i_rec_end_date > DATE '2002-10-01'
),
DateFiltered AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date) AS unique_return_days
    FROM 
        date_dim
    WHERE 
        d_date >= (DATE '2002-10-01' - INTERVAL '1 year') 
        AND d_date <= DATE '2002-10-01'
    GROUP BY 
        d_year
),
AggregatedReturns AS (
    SELECT 
        rb.return_item_sk,
        COUNT(*) AS total_returns,
        AVG(rb.returned_amt) AS avg_return_amount
    FROM 
        (SELECT 
            sr_item_sk AS return_item_sk, 
            sr_return_amt AS returned_amt
        FROM 
            store_returns 
        WHERE 
            sr_returned_date_sk IN (SELECT sr_returned_date_sk FROM RankedReturns WHERE rn = 1)
        ) rb
    GROUP BY 
        rb.return_item_sk
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.purchase_estimate,
    id.i_item_desc,
    id.item_size,
    ar.total_returns,
    ar.avg_return_amount,
    df.d_year,
    df.unique_return_days
FROM 
    CustomerDemographics cd
LEFT JOIN 
    AggregatedReturns ar ON cd.cd_demo_sk = ar.return_item_sk
JOIN 
    ItemDetails id ON ar.return_item_sk = id.i_item_sk
JOIN 
    DateFiltered df ON df.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    (cd.purchase_rank = 1 AND cd.cd_gender = 'F')
    OR (cd.purchase_rank > 2 AND id.i_current_price < 50)
ORDER BY 
    cd.cd_demo_sk, ar.total_returns DESC NULLS LAST;
