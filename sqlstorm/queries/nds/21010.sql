
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt) AS total_web_returned_amount,
        COUNT(DISTINCT wr_order_number) AS total_web_returns_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(c.cr_returning_customer_sk, w.wr_returning_customer_sk) AS customer_sk,
        COALESCE(c.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(c.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(w.total_web_returned_quantity, 0) AS total_web_returned_quantity,
        COALESCE(w.total_web_returned_amount, 0) AS total_web_returned_amount
    FROM 
        CustomerReturns c
    FULL OUTER JOIN 
        WebReturns w ON c.cr_returning_customer_sk = w.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cb.hd_income_band_sk,
        cb.hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics cb ON cd.cd_demo_sk = cb.hd_demo_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.total_returned_quantity + cr.total_web_returned_quantity) AS total_returned_products,
    SUM(cr.total_returned_amount + cr.total_web_returned_amount) AS total_refund_amount,
    CASE 
        WHEN SUM(cr.total_returned_quantity + cr.total_web_returned_quantity) > 0 
        THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status,
    DENSE_RANK() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY SUM(cr.total_returned_amount + cr.total_web_returned_amount) DESC) AS rank_by_returns
FROM 
    customer c
LEFT JOIN 
    CombinedReturns cr ON c.c_customer_sk = cr.customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    c.c_birth_year > 1975 AND
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status NOT IN ('S', 'D')) AND
    (cr.total_returned_quantity IS NOT NULL AND cr.total_returned_quantity > 1 OR 
     cr.total_web_returned_quantity IS NOT NULL AND cr.total_web_returned_quantity > 1)
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(cr.total_returned_amount + cr.total_web_returned_amount) > 100
ORDER BY 
    return_status, total_refund_amount DESC;
