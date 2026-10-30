
WITH RecursiveSales AS (
    SELECT 
        ss_store_sk, 
        COUNT(*) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        (SELECT AVG(ss_net_profit) FROM store_sales) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM store_sales
    GROUP BY ss_store_sk
),
AddressInfo AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS unique_addresses 
    FROM customer_address 
    GROUP BY ca_state
),
CustomerBehavior AS (
    SELECT 
        c_customer_sk,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    COALESCE(a.unique_addresses, 0) AS unique_addresses,
    rs.total_sales,
    rs.total_net_profit,
    rs.avg_net_profit,
    cb.female_count,
    cb.married_count,
    cb.avg_purchase_estimate
FROM store s
LEFT JOIN AddressInfo a ON s.s_state = a.ca_state
LEFT JOIN RecursiveSales rs ON s.s_store_sk = rs.ss_store_sk
LEFT JOIN CustomerBehavior cb ON cb.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
WHERE 
    s.s_city NOT LIKE '%Town%' 
    AND (rs.total_sales IS NOT NULL OR rs.total_net_profit IS NOT NULL)
ORDER BY 
    CASE 
        WHEN rs.total_net_profit > rs.avg_net_profit THEN 1 
        ELSE 0 
    END DESC,
    s.s_store_name;
