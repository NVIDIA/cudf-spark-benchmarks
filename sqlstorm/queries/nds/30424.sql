
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_per_item,
        DENSE_RANK() OVER (ORDER BY ws_quantity DESC) AS rank_by_quantity
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_spent_per_item
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_by_spending
    FROM 
        CustomerAnalytics
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_orders,
    tc.total_spent,
    tc.income_band,
    COALESCE(rs.ws_sales_price, 0) AS highest_sales_price,
    COALESCE(rs.rank_per_item, -1) AS sales_price_rank,
    COALESCE(rs.rank_by_quantity, -1) AS quantity_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales rs ON tc.c_customer_sk = rs.ws_order_number
WHERE 
    tc.rank_by_spending <= 10
ORDER BY 
    tc.total_spent DESC;
