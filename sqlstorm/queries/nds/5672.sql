
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        sr_store_sk, 
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank_return
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk BETWEEN 20220101 AND 20221231 
    GROUP BY 
        sr_item_sk, sr_store_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk, 
        rr.sr_store_sk, 
        rr.total_returns, 
        rr.total_returned_quantity, 
        rr.total_returned_amount
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank_return <= 5
),
StoreDetails AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        s.s_city, 
        s.s_state, 
        s.s_country
    FROM 
        store s
)
SELECT 
    tri.sr_store_sk, 
    sd.s_store_name, 
    sd.s_city, 
    sd.s_state, 
    sd.s_country, 
    tri.sr_item_sk, 
    tri.total_returns, 
    tri.total_returned_quantity, 
    tri.total_returned_amount
FROM 
    TopReturnedItems tri
JOIN 
    StoreDetails sd ON tri.sr_store_sk = sd.s_store_sk
ORDER BY 
    tri.total_returned_amount DESC;
