WITH RankedSales AS (
    SELECT 
        ws_sales_price,
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighSales AS (
    SELECT 
        ws_item_sk,
        MAX(ws_sales_price) AS max_price
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band, 
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY c.c_birth_month DESC) AS birth_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
StoreSalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        AVG(ss_sales_price) AS avg_price
    FROM 
        store_sales
    WHERE 
        ss_list_price > 0
    GROUP BY 
        ss_store_sk
),
AggregateData AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(ss.total_sales, 0) AS total_sales,
        CASE 
            WHEN ss.total_sales > 0 THEN ss.total_profit / ss.total_sales 
            ELSE NULL 
        END AS profit_per_sale
    FROM 
        store s
    LEFT JOIN 
        StoreSalesData ss ON s.s_store_sk = ss.ss_store_sk
),
FinalResults AS (
    SELECT 
        cte.c_customer_sk,
        cte.c_first_name,
        cte.c_last_name,
        ad.total_profit,
        SUM(CASE WHEN hs.rnk = 1 THEN hs.ws_sales_price ELSE 0 END) AS highest_web_sales_price
    FROM 
        CustomerCTE cte
    LEFT JOIN 
        RankedSales hs ON cte.c_customer_sk = hs.ws_item_sk
    LEFT JOIN 
        AggregateData ad ON ad.s_store_sk = (SELECT MIN(s_store_sk) FROM store) 
    WHERE 
        cte.birth_rank = 1 OR cte.income_band IS NULL
    GROUP BY 
        cte.c_customer_sk, cte.c_first_name, cte.c_last_name, ad.total_profit
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_profit,
    f.highest_web_sales_price,
    CASE 
        WHEN f.highest_web_sales_price IS NULL THEN 'No Sales'
        WHEN f.total_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalResults f
ORDER BY 
    f.total_profit DESC, 
    f.c_last_name ASC NULLS LAST;