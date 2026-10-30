
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10050
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
IncomeRanges AS (
    SELECT 
        hd.hd_income_band_sk,
        CASE
            WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL THEN 
                CONCAT('Income Range: $', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
            ELSE 
                'Unknown Income Range'
        END AS income_band_desc,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    cm.c_first_name,
    cm.c_last_name,
    cm.total_sales,
    cm.order_count,
    cm.unique_items,
    ir.income_band_desc,
    ir.household_count,
    ROW_NUMBER() OVER (ORDER BY cm.total_sales DESC) AS sales_rank
FROM 
    CustomerMetrics cm
JOIN 
    IncomeRanges ir ON cm.c_customer_sk = ir.hd_income_band_sk 
WHERE 
    cm.order_count > 5
ORDER BY 
    cm.total_sales DESC, cm.c_last_name ASC
LIMIT 100;
