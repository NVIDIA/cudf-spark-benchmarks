
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        rd.r_reason_desc AS return_reason
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason rd ON sr.sr_reason_sk = rd.r_reason_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_coupon_amt) AS total_coupons
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.return_reason,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.order_count, 0) AS order_count,
        COALESCE(si.total_coupons, 0) AS total_coupons
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    return_reason,
    total_sales,
    order_count,
    total_coupons,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
FROM 
    CombinedInfo
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, full_name;
