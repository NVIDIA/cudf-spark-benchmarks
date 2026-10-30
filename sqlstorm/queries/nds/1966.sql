
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
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
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_month DESC) AS gender_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        COALESCE(rs.total_sales, 0) AS total_sales,
        CASE 
            WHEN ci.gender_rank <= 10 THEN 'Top Customers'
            ELSE 'Regular Customers'
        END AS customer_rank_category
    FROM 
        CustomerInfo ci
        LEFT JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.customer_rank_category,
    SUM(iss.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT iss.ws_order_number) AS total_orders,
    MAX(iss.ws_net_paid_inc_tax) AS max_payment
FROM 
    SalesSummary ss
    LEFT JOIN web_sales iss ON ss.c_customer_sk = iss.ws_bill_customer_sk
WHERE 
    ss.total_sales > 0
GROUP BY 
    ss.c_customer_sk, ss.c_first_name, ss.c_last_name, ss.total_sales, ss.customer_rank_category
HAVING 
    COUNT(DISTINCT iss.ws_order_number) > 5
ORDER BY 
    total_sales DESC, total_net_profit DESC
LIMIT 100;
