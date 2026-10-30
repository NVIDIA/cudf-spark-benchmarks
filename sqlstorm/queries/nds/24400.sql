
WITH  address_nesting AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_name, 
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS row_num
    FROM 
        customer_address
    WHERE 
        ca_country IS NOT NULL
), demographics_summary AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS count, 
        AVG(cd_purchase_estimate) AS avg_purchase_est,
        SUM(cd_dep_count) AS total_dependents,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), return_analysis AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_store_sk
), sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_address_id,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.cd_gender,
    d.count AS demographic_count,
    rs.total_returns,
    rs.total_returned_amount,
    sd.total_sold,
    sd.avg_sales_price,
    CASE 
        WHEN sd.total_sold > 100 THEN 'High Performer' 
        WHEN sd.total_sold BETWEEN 50 AND 100 THEN 'Moderate Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    address_nesting a
LEFT JOIN 
    demographics_summary d ON a.row_num = d.count
LEFT JOIN 
    return_analysis rs ON a.ca_address_sk = rs.sr_store_sk
LEFT JOIN 
    sales_data sd ON a.ca_address_sk = sd.ws_item_sk
WHERE 
    (d.cd_gender IS NOT NULL OR d.count > 10)
    AND (rs.total_returned_amount IS NULL OR rs.total_returned_amount < 1000)
ORDER BY 
    a.ca_city, d.cd_gender DESC;
