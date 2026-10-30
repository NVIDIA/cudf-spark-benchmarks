
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
item_analysis AS (
    SELECT 
        i_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_sk
),
returns_summary AS (
    SELECT 
        COALESCE(sr_reason_sk, wr_reason_sk) AS reason_sk,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) + COUNT(DISTINCT wr_order_number) AS total_return_orders  
    FROM 
        store_returns 
    FULL OUTER JOIN 
        web_returns ON sr_item_sk = wr_item_sk
    GROUP BY 
        COALESCE(sr_reason_sk, wr_reason_sk)
)
SELECT 
    ds.d_year,
    geo.ca_country,
    ds.d_month_seq,
    ds.d_week_seq,
    ds.d_day_name,
    d_summary.cd_gender,
    d_summary.customer_count,
    d_summary.avg_purchase_estimate,
    d_summary.married_count,
    d_summary.max_dependents,
    item.i_item_id,
    item_analysis.total_quantity_sold,
    item_analysis.total_sales,
    item_analysis.total_profit,
    item_analysis.item_rank,
    r_summary.reason_sk,
    r_summary.total_returned,
    r_summary.total_return_orders
FROM 
    date_dim ds
LEFT JOIN 
    customer_address geo ON geo.ca_address_sk = ds.d_date_sk % (SELECT COUNT(ca_address_sk) FROM customer_address) + 1
JOIN 
    demographic_summary d_summary ON d_summary.customer_count > 0
JOIN 
    item ON item.i_item_desc LIKE '%Special%' 
LEFT JOIN 
    item_analysis ON item_analysis.i_item_sk = item.i_item_sk AND item_analysis.order_count > 10
LEFT JOIN 
    returns_summary r_summary ON r_summary.reason_sk IS NOT NULL
WHERE 
    (ds.d_year = 2023 OR ds.d_year = 2022)
    AND (geo.ca_country LIKE 'United%' OR geo.ca_country IS NULL)
ORDER BY 
    ds.d_day_name, 
    d_summary.customer_count DESC, 
    item_analysis.total_profit DESC
LIMIT 50 OFFSET 20;
