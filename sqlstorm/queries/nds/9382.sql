
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2500 
        AND w.w_warehouse_name LIKE 'Central%'
    GROUP BY 
        w.w_warehouse_name, i.i_item_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ABS(AVG(ss.total_sales)) AS avg_sales_per_gender
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.total_quantity > 0
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
IncomeAnalysis AS (
    SELECT 
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS income_bracket_count,
        AVG(ss.avg_net_paid) AS avg_sales_in_bracket
    FROM 
        SalesSummary ss
    JOIN 
        household_demographics hd ON ss.total_quantity > 0
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ia.ib_lower_bound, 
    ia.ib_upper_bound, 
    ia.income_bracket_count, 
    ia.avg_sales_in_bracket
FROM 
    CustomerDemographics cd
JOIN 
    IncomeAnalysis ia ON cd.avg_sales_per_gender > ia.avg_sales_in_bracket
ORDER BY 
    cd.cd_gender, cd.cd_marital_status, ia.ib_lower_bound;
