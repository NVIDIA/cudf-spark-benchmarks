
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS ranking
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
AggregateDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
    COALESCE(cr.return_count, 0) AS total_return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    ad.avg_purchase_estimate,
    ad.customer_count
FROM 
    item i
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.ranking = 1
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN AggregateDemographics ad ON ad.customer_count > 10
WHERE 
    (rs.total_quantity IS NOT NULL OR cr.return_count IS NOT NULL)
    AND (ad.avg_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'M' AND cd_marital_status = 'S'))
ORDER BY 
    total_sales_quantity DESC NULLS LAST;
