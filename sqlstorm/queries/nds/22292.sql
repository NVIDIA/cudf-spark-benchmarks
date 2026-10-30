
WITH ranked_sales AS (
    SELECT 
        ws_web_site_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_web_site_sk, 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country IS NOT NULL
), 
return_statistics AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ai.full_address,
    rs.total_quantity,
    rs.total_profit,
    r.total_returns,
    r.total_return_amount,
    CASE 
        WHEN r.total_returns IS NULL THEN 'No Returns'
        WHEN r.total_returns > 5 THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status
FROM 
    customer_info ci
LEFT JOIN 
    address_info ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_web_site_sk
LEFT JOIN 
    return_statistics r ON ci.c_customer_sk = r.cr_returning_customer_sk
WHERE 
    ci.cd_gender IN ('M', 'F')
    AND (ci.cd_marital_status = 'S' OR ci.cd_purchase_estimate > 1000)
    AND (rs.total_profit > (SELECT AVG(total_profit) FROM ranked_sales) OR rs.total_quantity IN (SELECT SUM(ws_quantity) FROM web_sales GROUP BY ws_item_sk HAVING SUM(ws_quantity) >= 100))
ORDER BY 
    ci.cd_purchase_estimate DESC, 
    return_status, 
    rs.total_profit DESC
LIMIT 100;
