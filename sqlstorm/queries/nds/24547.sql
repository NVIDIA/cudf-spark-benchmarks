
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        total_sales,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            ELSE 'Regular Value'
        END AS order_category
    FROM 
        RankedSales
    WHERE 
        price_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(cd_demo_sk) OVER (PARTITION BY cd_gender) AS gender_count
    FROM 
        customer_demographics
    WHERE 
        cd_marital_status = 'S'
),
FinalReport AS (
    SELECT 
        COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
        SUM(COALESCE(h.total_returned, 0)) AS returns,
        MAX(CASE WHEN h.total_returned > 0 THEN 'Yes' ELSE 'No' END) AS has_returns,
        MAX(case when hv.order_category = 'High Value' then hv.ws_sales_price else 0 end) as max_high_value_order,
        SUM(DISTINCT cd.gender_count) AS total_gender_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns h ON c.c_customer_sk = h.sr_customer_sk
    LEFT JOIN 
        HighValueOrders hv ON c.c_customer_sk = hv.ws_order_number
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    customer_id,
    returns,
    has_returns,
    CASE 
        WHEN returns IS NULL THEN 'No Returns'
        WHEN returns > 10 THEN 'Frequent Returns'
        ELSE 'Occasional Returns'
    END AS return_behavior,
    total_gender_count
FROM 
    FinalReport
WHERE 
    (returns IS NOT NULL AND returns > 5) 
    OR (has_returns = 'Yes' AND total_gender_count > 1)
ORDER BY 
    returns DESC, customer_id;
