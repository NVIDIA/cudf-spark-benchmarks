
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_count AS (
    SELECT 
        ca.ca_country,
        COUNT(ca.ca_address_sk) AS num_addresses
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_country
),
return_analysis AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
combined_sales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (COALESCE(s.total_net_sales, 0) - COALESCE(r.total_returns, 0)) AS net_after_returns
    FROM 
        sales_data s
    FULL OUTER JOIN 
        return_analysis r ON s.ws_item_sk = r.sr_item_sk
)
SELECT 
    r.c_customer_id,
    r.cd_gender,
    a.ca_country,
    cs.total_sales,
    cs.total_returns,
    cs.net_after_returns
FROM 
    ranked_customers r
LEFT JOIN 
    combined_sales cs ON r.c_customer_sk = cs.ws_item_sk
JOIN 
    address_count a ON a.num_addresses > 10
WHERE 
    r.purchase_rank <= 5 AND 
    (r.cd_marital_status = 'M' OR r.cd_purchase_estimate > 100) AND 
    (a.ca_country IS NOT NULL OR r.cd_gender IS NULL)
ORDER BY 
    r.cd_gender DESC, cs.net_after_returns DESC
LIMIT 100;
