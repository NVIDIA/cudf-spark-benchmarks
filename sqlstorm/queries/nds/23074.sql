
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS unique_addresses, 
        SUM(CASE WHEN ca_zip IS NULL THEN 1 ELSE 0 END) AS null_zip_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
        MAX(cd_dep_count) AS max_dep_count, 
        MIN(cd_dep_employed_count) AS min_dep_employed_count,
        COUNT(CASE WHEN cd_credit_rating IS NULL THEN 1 ELSE NULL END) AS null_credit_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit, 
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
JoinedData AS (
    SELECT 
        A.ca_state, 
        D.cd_gender, 
        S.total_profit, 
        S.total_orders,
        CASE 
            WHEN S.total_profit IS NULL THEN 'No Sales'
            WHEN S.total_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM 
        AddressStats A
    FULL OUTER JOIN 
        DemographicStats D ON A.null_zip_count > 0
    FULL OUTER JOIN 
        SalesData S ON D.null_credit_count > 0
)
SELECT 
    jd.ca_state,
    jd.cd_gender,
    jd.total_profit,
    jd.total_orders,
    jd.profit_status,
    COALESCE(jd.total_orders, 0) AS orders_or_zero,
    jd.total_profit / NULLIF(jd.total_orders, 0) AS average_profit_per_order,
    CASE 
        WHEN jd.total_orders IS NOT NULL AND jd.total_orders > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume_category
FROM 
    JoinedData jd
WHERE 
    jd.ca_state IS NOT NULL AND 
    (jd.cd_gender IS NOT NULL OR jd.total_profit > 1000)
ORDER BY 
    average_profit_per_order DESC NULLS LAST;
