
WITH Address_Mapping AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        CONCAT(ca_city, ', ', ca_state) AS city_state
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
),
Customer_Demographics AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT cd_demo_sk) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Total_Sales AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
),
Store_Sales AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    am.city_state,
    am.address_count,
    cd.cd_gender,
    cd.demo_count,
    ts.total_sales,
    ss.total_profit
FROM 
    Address_Mapping am
JOIN 
    Customer_Demographics cd ON 1=1
CROSS JOIN 
    Total_Sales ts
JOIN 
    Store_Sales ss ON ss.ss_store_sk IN (SELECT DISTINCT s_store_sk FROM store)
WHERE 
    am.address_count > 10
ORDER BY 
    am.address_count DESC, 
    cd.cd_gender;
