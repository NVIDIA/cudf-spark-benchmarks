
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS distinct_returned_items,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        MAX(sr_return_amt_inc_tax) AS max_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        COALESCE(cd_dep_count, 0) AS dep_count
    FROM 
        customer_demographics
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        CASE 
            WHEN i_current_price > 100 THEN 'Premium' 
            ELSE 'Standard' 
        END AS price_category
    FROM 
        item
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cr.distinct_returned_items,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        sd.total_spent,
        sd.order_count,
        CASE 
            WHEN cr.total_returned_amount IS NULL THEN 'No Returns' 
            ELSE 
                CASE 
                    WHEN cr.total_returned_quantity > 5 THEN 'Frequent Returner'
                    ELSE 'Occasional Returner'
                END 
        END AS return_behavior
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    FULL OUTER JOIN 
        SalesData sd ON cr.sr_customer_sk = sd.customer_sk
)
SELECT 
    fa.cd_gender,
    fa.cd_marital_status,
    fa.return_behavior,
    CONCAT('Total Returned Amount: ', COALESCE(fa.total_returned_amount, 0)) AS return_amount_description,
    LAG(fa.order_count, 1, 0) OVER (PARTITION BY fa.cd_gender ORDER BY fa.total_spent DESC) AS previous_order_count,
    CASE 
        WHEN fa.total_spent IS NULL THEN 'Inactive Customer' 
        WHEN fa.total_spent > 1000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_value_category,
    ROW_NUMBER() OVER (PARTITION BY fa.return_behavior ORDER BY fa.total_spent DESC) AS rank_within_behavior
FROM 
    FinalAnalysis fa
WHERE
    (fa.return_behavior IS NOT NULL OR fa.total_spent > 500)
    AND (fa.cd_gender IS NOT NULL OR fa.cd_marital_status IS NOT NULL)
ORDER BY 
    fa.cd_gender, fa.total_spent DESC;
