
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_demo_sk,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender_label
    FROM
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TopSales AS (
    SELECT
        s.ws_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        RANK() OVER (PARTITION BY s.ws_sold_date_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM
        store_sales AS ss
    JOIN 
        web_sales AS s ON ss.ss_item_sk = s.ws_item_sk
    WHERE 
        ss.ss_net_paid > 100
    GROUP BY 
        s.ws_sold_date_sk, ss.ss_store_sk
)
SELECT 
    ds.d_date AS sale_date,
    SUM(ts.store_net_profit) AS total_profit,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    CASE 
        WHEN SUM(ts.store_net_profit) IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profitability_status
FROM
    date_dim AS ds
LEFT JOIN 
    TopSales AS ts ON ds.d_date_sk = ts.ws_sold_date_sk AND ts.store_rank <= 5
LEFT JOIN 
    CustomerDetails AS cs ON cs.c_customer_sk IN (SELECT DISTINCT ss.ss_customer_sk FROM store_sales AS ss WHERE ss.ss_net_profit > 0)
WHERE 
    ds.d_year = 2023
GROUP BY 
    ds.d_date
ORDER BY 
    sale_date;
