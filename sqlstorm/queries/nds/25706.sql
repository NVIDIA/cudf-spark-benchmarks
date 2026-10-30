
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS TotalAddresses,
        SUM(CASE WHEN ca_city IS NOT NULL THEN 1 ELSE 0 END) AS NonNullCities,
        AVG(COALESCE(ca_gmt_offset, 0)) AS AverageGMTOffset,
        MAX(LENGTH(ca_street_name)) AS MaxStreetNameLength
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS TotalDemographics,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        MAX(cd_dep_college_count) AS MaxCollegeDependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ReturnSummary AS (
    SELECT 
        sr_reason_sk, 
        COUNT(*) AS ReturnCount,
        SUM(sr_return_quantity) AS TotalReturnedQuantity,
        SUM(sr_return_amt) AS TotalReturnAmount
    FROM 
        store_returns
    GROUP BY 
        sr_reason_sk
),
ItemSummary AS (
    SELECT 
        i_category,
        COUNT(i_item_sk) AS ItemCount,
        AVG(i_current_price) AS AvgCurrentPrice,
        MAX(i_size) AS MaxSize
    FROM 
        item 
    GROUP BY 
        i_category
)
SELECT 
    a.ca_state,
    a.TotalAddresses,
    a.NonNullCities,
    a.AverageGMTOffset,
    d.cd_gender,
    d.TotalDemographics,
    d.AvgPurchaseEstimate,
    r.ReturnCount,
    r.TotalReturnedQuantity,
    r.TotalReturnAmount,
    i.ItemCount,
    i.AvgCurrentPrice,
    i.MaxSize
FROM 
    AddressSummary a
JOIN 
    DemoSummary d ON 1=1
JOIN 
    ReturnSummary r ON 1=1
JOIN 
    ItemSummary i ON 1=1
ORDER BY 
    a.ca_state, d.cd_gender;
