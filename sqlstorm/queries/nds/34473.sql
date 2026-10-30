
WITH  SalesAccumulation AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS row_num
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk, ws_sales_price
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ra.ca_city,
        r.r_reason_desc
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ra ON c.c_current_addr_sk = ra.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND ra.ca_state = 'CA'
),
TotalSales AS (
    SELECT 
        s.ws_order_number,
        SUM(s.ws_ext_sales_price) AS total_sales,
        SUM(s.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT s.ws_item_sk) AS item_count
    FROM 
        web_sales s
    GROUP BY 
        s.ws_order_number
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sa.total_sales,
    sa.total_discount,
    ta.total_quantity,
    ta.ws_sales_price,
    sa.item_count,
    COALESCE(ta.total_quantity, 0) AS quantity_on_hand,
    CASE 
        WHEN ta.total_quantity IS NULL THEN 'Out of Stock'
        WHEN ta.total_quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    CustomerInfo ci
JOIN 
    TotalSales sa ON ci.c_customer_sk = sa.ws_order_number
LEFT JOIN 
    SalesAccumulation ta ON sa.ws_order_number = ta.ws_order_number 
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    sa.total_sales DESC, 
    ci.c_last_name ASC, 
    ci.c_first_name ASC
LIMIT 100;
