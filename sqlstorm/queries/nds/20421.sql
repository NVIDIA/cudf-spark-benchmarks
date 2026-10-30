
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid_inc_ship_tax,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid_inc_ship_tax DESC) as sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = (SELECT MAX(d_year) FROM date_dim)
        )
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    GROUP BY 
        sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate > 50000 THEN 'High'
            WHEN cd_purchase_estimate BETWEEN 20000 AND 50000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_power,
        COUNT(cd_demo_sk) OVER(PARTITION BY cd_gender) AS gender_count
    FROM 
        customer_demographics
)
SELECT 
    cs.ws_order_number,
    cs.ws_item_sk,
    cs.ws_quantity,
    cs.ws_net_paid_inc_ship_tax,
    r.total_returned,
    r.total_returned_amt,
    cd.cd_gender,
    cd.purchase_power,
    CASE 
        WHEN cs.ws_net_paid_inc_ship_tax IS NULL THEN 'No Sales'
        WHEN r.total_returned > 0 THEN 'Returned Item'
        ELSE 'Active Sale'
    END AS sale_status
FROM 
    web_sales cs
LEFT JOIN 
    HighValueReturns r ON cs.ws_item_sk = r.sr_item_sk
JOIN 
    CustomerDemographics cd ON cs.ws_bill_cdemo_sk = cd.cd_demo_sk 
WHERE 
    cs.ws_order_number IN (SELECT ws_order_number FROM RankedSales WHERE sales_rank = 1)
    AND (cd.gender_count > 10 OR cd.cd_marital_status IS NULL)
ORDER BY 
    cs.ws_order_number, cd.cd_gender;
