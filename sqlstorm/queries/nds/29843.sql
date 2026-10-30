
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS address_count,
        COUNT(DISTINCT ca_city) AS city_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
CustomerCounts AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk 
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        'web' AS source,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_sales_price) AS average_sales_price
    FROM 
        web_sales 
    UNION ALL
    SELECT 
        'store' AS source,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_sales_price) AS total_sales_amount,
        AVG(ss_sales_price) AS average_sales_price
    FROM 
        store_sales 
),
FinalReport AS (
    SELECT 
        ac.ca_state, 
        ac.address_count, 
        ac.city_count,
        cc.cd_gender,
        cc.customer_count,
        ss.total_sales,
        ss.total_sales_amount,
        ss.average_sales_price
    FROM 
        AddressCounts ac
        CROSS JOIN CustomerCounts cc
        CROSS JOIN (SELECT SUM(total_sales) AS total FROM SalesStats) AS total_sales_aggregate 
        JOIN SalesStats ss ON true 
    WHERE 
        ac.address_count > 100
)
SELECT 
    ca_state, 
    address_count, 
    city_count, 
    cd_gender, 
    customer_count, 
    total_sales, 
    total_sales_amount, 
    average_sales_price
FROM 
    FinalReport
ORDER BY 
    address_count DESC, 
    total_sales_amount DESC;
