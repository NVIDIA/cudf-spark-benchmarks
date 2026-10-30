WITH  AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        AVG(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_purchase_estimate ELSE NULL END) AS avg_spending
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN 
        store s ON s.s_store_sk = c.c_current_addr_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
AnnualSales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit_year
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    cs.store_count,
    cs.avg_spending,
    sd.total_quantity,
    sd.total_profit,
    CASE 
        WHEN sd.profit_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS profit_category,
    CASE 
        WHEN asd.total_profit_year IS NULL THEN 'No Sales Data'
        ELSE 'Sales Available'
    END AS sales_data_availability
FROM 
    CustomerSummary cs
LEFT JOIN 
    AddressHierarchy ah ON ah.city_rank = 1
LEFT JOIN 
    SalesData sd ON cs.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    AnnualSales asd ON asd.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
WHERE 
    (cs.avg_spending IS NOT NULL OR cs.store_count > 0)
AND 
    (cs.c_birth_year BETWEEN 1980 AND 1990 OR cs.c_birth_year IS NULL)
ORDER BY 
    sd.total_profit DESC NULLS LAST,
    cs.store_count DESC;