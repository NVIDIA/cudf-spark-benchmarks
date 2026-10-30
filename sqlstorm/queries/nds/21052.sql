
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim
            WHERE d_year = 2023 AND d_current_day = 'Y'
        )
),
DailyReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim
            WHERE d_year = 2023 AND d_dow = 7
        )
    GROUP BY 
        cr.cr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
        AND cd.cd_dep_count IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_id,
    COALESCE(rs.ws_sales_price, 0) AS last_known_price,
    COALESCE(dr.total_returned, 0) AS total_returns,
    CASE 
        WHEN COALESCE(dr.total_returned, 0) > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS sales_status,
    cd.customer_count,
    cd.max_purchase_estimate
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
LEFT JOIN 
    DailyReturns dr ON i.i_item_sk = dr.cr_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.customer_count = (
        SELECT 
            MAX(customer_count)
        FROM 
            CustomerDemographics
    )
WHERE 
    (rs.ws_sales_price IS NOT NULL OR dr.total_returned IS NOT NULL)
    AND (i.i_current_price IS NOT NULL OR i.i_item_desc LIKE '%Special%')
ORDER BY 
    cd.customer_count DESC, last_known_price DESC;
