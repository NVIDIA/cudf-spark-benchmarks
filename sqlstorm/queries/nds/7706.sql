
WITH SalesData AS (
    SELECT 
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        cd_gender,
        d_year,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023 AND cd_gender = 'F'
),
AggregatedData AS (
    SELECT 
        d_month_seq,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        SalesData
    GROUP BY 
        d_month_seq
)
SELECT 
    ad.d_month_seq,
    ad.total_profit,
    ad.total_quantity,
    ad.avg_sales_price,
    RANK() OVER (ORDER BY ad.total_profit DESC) AS rank_by_profit
FROM 
    AggregatedData AS ad
ORDER BY 
    ad.d_month_seq;
