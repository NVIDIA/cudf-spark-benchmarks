
WITH ranked_orders AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        COALESCE(NULLIF(ws.ws_sales_price - ws.ws_ext_discount_amt, 0), 1) AS effective_price
    FROM 
        web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 30
),
top_items AS (
    SELECT 
        ro.ws_item_sk,
        ro.ws_order_number,
        ro.ws_sales_price,
        ro.total_quantity_sold
    FROM 
        ranked_orders ro
    WHERE 
        ro.price_rank <= 10
),
address_summary AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca 
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_country
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
final_report AS (
    SELECT 
        ti.ws_item_sk,
        ti.ws_order_number,
        ti.ws_sales_price,
        ti.total_quantity_sold,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        asu.customer_count,
        asu.avg_purchase_estimate
    FROM 
        top_items ti
    LEFT JOIN 
        returns_summary rs ON ti.ws_item_sk = rs.sr_item_sk
    JOIN 
        address_summary asu ON asu.customer_count > 10
)
SELECT 
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.ws_sales_price,
    fr.total_quantity_sold,
    fr.total_returned,
    fr.total_return_amt,
    fr.customer_count,
    fr.avg_purchase_estimate,
    CASE 
        WHEN fr.total_returned > fr.total_quantity_sold THEN 'High Return Rate'
        WHEN fr.total_returned = 0 AND fr.total_quantity_sold > 0 THEN 'No Returns'
        ELSE 'Normal Return Rate'
    END AS return_rate_classification
FROM 
    final_report fr
WHERE 
    fr.avg_purchase_estimate IS NOT NULL
ORDER BY 
    fr.total_quantity_sold DESC, fr.ws_sales_price DESC
LIMIT 100;
