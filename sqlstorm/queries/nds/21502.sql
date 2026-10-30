WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND i.i_rec_end_date > cast('2002-10-01' as date)
),
HighValueSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.total_sales,
        r.order_count
    FROM 
        RankedSales r
    WHERE 
        r.price_rank = 1 AND r.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT h.hd_demo_sk) AS household_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count, ca.ca_city, ca.ca_state
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(hv.ws_sales_price) AS high_value_sales,
        ci.household_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        HighValueSales hv ON ci.c_customer_sk = hv.ws_item_sk  
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.household_count
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.high_value_sales,
    fr.household_count,
    CASE 
        WHEN fr.high_value_sales > 1000 THEN 'High Value'
        WHEN fr.high_value_sales IS NULL THEN 'No Sales'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    FinalReport fr
WHERE 
    fr.household_count > 0
ORDER BY 
    fr.high_value_sales DESC NULLS LAST
LIMIT 100
;