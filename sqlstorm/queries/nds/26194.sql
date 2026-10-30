
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
MaxReturnStats AS (
    SELECT 
        sr_reason_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        AVG(sr_return_tax) AS avg_return_tax
    FROM 
        store_returns 
    GROUP BY 
        sr_reason_sk
),
WebSalesStats AS (
    SELECT 
        wp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales 
    INNER JOIN 
        web_page ON ws_web_page_sk = wp_web_page_sk 
    GROUP BY 
        wp_type
)

SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    r.total_returned_quantity,
    r.avg_return_tax,
    w.wp_type,
    w.total_sales,
    w.total_orders,
    w.avg_net_profit
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.customer_count > 1000
JOIN 
    MaxReturnStats r ON r.total_returned_quantity > 50
JOIN 
    WebSalesStats w ON w.total_sales > 10000
ORDER BY 
    a.ca_state, c.cd_gender, w.total_sales DESC;
