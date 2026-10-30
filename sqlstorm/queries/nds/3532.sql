
WITH RevenueCTE AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2419 AND 2450
    GROUP BY 
        cs_item_sk
),
HighProfitItems AS (
    SELECT 
        R1.cs_item_sk,
        R1.total_net_profit,
        R1.order_count,
        ROW_NUMBER() OVER (PARTITION BY R1.cs_item_sk ORDER BY R1.total_net_profit DESC) AS rank
    FROM 
        RevenueCTE R1
)
SELECT 
    C.c_customer_id,
    C.c_first_name,
    C.c_last_name,
    COALESCE(CA.ca_city, 'Unknown') AS city,
    COALESCE(HD.hd_buy_potential, 'Not Specified') AS potential,
    SUM(CASE WHEN W.ws_sales_price IS NOT NULL THEN W.ws_sales_price ELSE 0 END) AS total_web_sales,
    SUM(CASE WHEN S.ss_sales_price IS NOT NULL THEN S.ss_sales_price ELSE 0 END) AS total_store_sales,
    GREATEST(SUM(W.ws_net_profit), SUM(S.ss_net_profit)) AS max_profit
FROM 
    customer C
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    web_sales W ON W.ws_bill_customer_sk = C.c_customer_sk
LEFT JOIN 
    store_sales S ON S.ss_customer_sk = C.c_customer_sk
LEFT JOIN 
    household_demographics HD ON HD.hd_demo_sk = C.c_current_hdemo_sk
JOIN 
    HighProfitItems HPI ON W.ws_item_sk = HPI.cs_item_sk OR S.ss_item_sk = HPI.cs_item_sk
WHERE 
    HPI.rank <= 10 
GROUP BY 
    C.c_customer_id, C.c_first_name, C.c_last_name, CA.ca_city, HD.hd_buy_potential
HAVING 
    MAX(HPI.total_net_profit) > 5000
ORDER BY 
    total_web_sales DESC, max_profit DESC;
