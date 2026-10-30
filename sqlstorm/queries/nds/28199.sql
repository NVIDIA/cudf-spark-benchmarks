
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
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        asales.total_net_profit,
        asales.total_orders,
        asales.distinct_items_sold,
        ROW_NUMBER() OVER (ORDER BY asales.total_net_profit DESC) AS rank
    FROM 
        CustomerInfo ci
    JOIN 
        AggregateSales asales ON ci.c_customer_sk = asales.ws_bill_customer_sk
)
SELECT 
    rank,
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    cd_dep_employed_count,
    total_net_profit,
    total_orders,
    distinct_items_sold
FROM 
    RankedCustomers
WHERE 
    rank <= 100
ORDER BY 
    total_net_profit DESC;
