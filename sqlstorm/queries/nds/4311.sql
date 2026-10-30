
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sd.total_sales,
    sd.avg_net_profit,
    cr.unique_items_returned,
    cr.total_returned,
    CASE 
        WHEN cr.total_returned IS NULL THEN 'No Returns'
        WHEN cr.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    CustomerDemographics AS cd
LEFT JOIN 
    SalesData AS sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns AS cr ON cd.c_customer_sk = cr.sr_customer_sk
WHERE 
    (cd.cd_purchase_estimate > 100 OR cd.cd_credit_rating = 'Excellent')
    AND (cr.total_returned IS NULL OR cr.unique_items_returned > 2)
ORDER BY 
    sd.total_sales DESC, cd.cd_gender;
