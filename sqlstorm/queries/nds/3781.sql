
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(rs.total_net_profit) AS total_net_profit,
        COUNT(rs.ws_bill_customer_sk) AS orders_count
    FROM 
        CustomerInfo ci
    JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    ci.*,
    CASE 
        WHEN total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Profitable Customer'
    END AS customer_status,
    COALESCE(orders_count, 0) AS orders_number
FROM 
    SalesSummary ci
ORDER BY 
    total_net_profit DESC NULLS LAST;
