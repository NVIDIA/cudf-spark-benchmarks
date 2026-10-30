
WITH  Customer_Income AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_demo_sk ORDER BY hd.hd_income_band_sk) AS rn
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Daily_Sales AS (
    SELECT
        d.d_date AS sale_date,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        d.d_date
),
Top_Selling_Items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
    ORDER BY 
        total_quantity DESC
    LIMIT 10
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Sales_By_Customer AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        ci.hd_buy_potential
    FROM 
        Customer_Summary cs
    JOIN 
        Customer_Income ci ON cs.c_customer_sk = ci.hd_demo_sk
    WHERE 
        ci.rn = 1 
),
Final_Report AS (
    SELECT 
        d.sale_date,
        d.total_sales,
        COALESCE(SUM(sbc.total_profit), 0) AS total_profit_by_customer,
        COUNT(DISTINCT ti.i_item_sk) AS top_item_count
    FROM 
        Daily_Sales d
    LEFT JOIN 
        Sales_By_Customer sbc ON d.sale_date = DATE '2002-10-01' 
    LEFT JOIN 
        Top_Selling_Items ti ON sbc.total_orders > 0
    GROUP BY 
        d.sale_date, d.total_sales
)
SELECT 
    FR.sale_date,
    FR.total_sales,
    FR.total_profit_by_customer,
    FR.top_item_count
FROM 
    Final_Report FR
WHERE 
    FR.total_sales > 1000
ORDER BY 
    FR.sale_date DESC;
