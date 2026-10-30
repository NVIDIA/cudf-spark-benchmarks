
WITH  SalesAnalytics AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn,
        COALESCE(SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number), 0) AS cumulative_quantity,
        ws.ws_sold_date_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws1.ws_sales_price) FROM web_sales ws1 WHERE ws1.ws_sold_date_sk > 1000)
),
HighVolumeSales AS (
    SELECT 
        sa.ws_item_sk,
        SUM(sa.ws_quantity) AS total_sales,
        AVG(sa.ws_sales_price) AS avg_price,
        MAX(sa.ws_sales_price) AS max_price
    FROM 
        SalesAnalytics sa
    WHERE 
        sa.cumulative_quantity > 10 AND sa.rn <= 5
    GROUP BY 
        sa.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(c.c_customer_sk) AS address_count
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
    HAVING 
        COUNT(c.c_customer_sk) > 0
    ORDER BY 
        address_count DESC
)
SELECT 
    hvs.ws_item_sk,
    hvs.total_sales,
    hvs.avg_price,
    hvs.max_price,
    cd.cd_gender,
    ca.ca_city,
    COUNT(DISTINCT cd.cd_demo_sk) AS unique_customer_gender
FROM 
    HighVolumeSales hvs
JOIN 
    CustomerDemographics cd ON hvs.ws_item_sk = cd.cd_demo_sk
JOIN 
    CustomerAddress ca ON cd.customer_count > 5
GROUP BY 
    hvs.ws_item_sk, hvs.total_sales, hvs.avg_price, hvs.max_price, cd.cd_gender, ca.ca_city
HAVING 
    COALESCE(MAX(hvs.avg_price), 0) > 0 AND 
    COUNT(DISTINCT cd.cd_demo_sk) > 2
ORDER BY 
    hvs.total_sales DESC, hvs.avg_price ASC
LIMIT 10;
