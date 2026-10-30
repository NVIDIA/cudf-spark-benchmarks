
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
ProfitAnalysis AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        cd.customer_count,
        cd.avg_purchase_estimate,
        CASE 
            WHEN sd.total_profit > 10000 THEN 'High'
            WHEN sd.total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerData cd ON sd.ws_item_sk = cd.cd_demo_sk
)
SELECT 
    pa.profit_level,
    COUNT(*) AS item_count,
    SUM(pa.total_quantity) AS total_quantity,
    SUM(pa.total_sales) AS total_sales,
    SUM(pa.total_profit) AS total_profit,
    AVG(pa.customer_count) AS avg_customers,
    AVG(pa.avg_purchase_estimate) AS avg_estimate
FROM 
    ProfitAnalysis pa
GROUP BY 
    pa.profit_level
ORDER BY 
    total_profit DESC;
