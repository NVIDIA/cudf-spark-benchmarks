
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sa.ca_city,
        sa.ca_state,
        sa.ca_country,
        iv.inv_quantity_on_hand,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        inventory iv ON ws.ws_item_sk = iv.inv_item_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND sa.ca_state IN ('CA', 'NY', 'TX')
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450594
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, 
        sa.ca_city, sa.ca_state, sa.ca_country, iv.inv_quantity_on_hand, 
        ws.ws_net_paid, ws.ws_ext_discount_amt
), SalesPerformance AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.inv_quantity_on_hand,
        ci.ws_net_paid,
        ci.ws_ext_discount_amt,
        ci.total_quantity,
        ci.order_count,
        (ci.total_quantity * ci.ws_net_paid) AS total_sales_value
    FROM 
        CustomerInfo ci
)
SELECT 
    *,
    CASE 
        WHEN total_sales_value > 10000 THEN 'High Value'
        WHEN total_sales_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesPerformance
ORDER BY 
    total_sales_value DESC
LIMIT 100;
