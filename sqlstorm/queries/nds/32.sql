
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
WebSalesSummary AS (
    SELECT 
        w.web_site_id,
        SUM(s.ws_net_paid) AS total_sales,
        AVG(s.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT s.ws_order_number) AS order_count
    FROM 
        web_sales s
    JOIN 
        web_site w ON s.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'USA'
    GROUP BY 
        w.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
    GROUP BY 
        cd.cd_gender
)
SELECT 
    w.web_site_id,
    w.total_sales,
    w.avg_net_profit,
    c.cd_gender,
    c.customer_count,
    c.avg_estimate
FROM 
    WebSalesSummary w
LEFT JOIN 
    CustomerDemographics c ON w.total_sales > 1000 OR c.customer_count IS NOT NULL
WHERE 
    w.total_sales IS NOT NULL
ORDER BY 
    w.total_sales DESC
LIMIT 10;
