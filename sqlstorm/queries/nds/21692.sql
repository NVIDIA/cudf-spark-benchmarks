
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS rnk
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price > (
            SELECT 
                AVG(cs_inner.cs_sales_price)
            FROM 
                catalog_sales cs_inner
            WHERE 
                cs_inner.cs_item_sk = cs.cs_item_sk
                AND cs_inner.cs_sold_date_sk BETWEEN 20220101 AND 20221231
        )
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT CASE WHEN r.r_reason_sk IS NULL THEN NULL END) AS null_reasons_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        cd.cd_gender = 'M' AND cd.cd_marital_status IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
PriceSummary AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_ext_discount_amt) AS max_discount
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws_inner.ws_sold_date_sk) FROM web_sales ws_inner)
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT rs.cs_order_number) AS high_value_orders,
    ps.total_net_profit,
    ps.max_discount
FROM 
    CustomerInfo ci
JOIN 
    RankedSales rs ON ci.c_customer_sk = rs.cs_item_sk
JOIN 
    PriceSummary ps ON ps.i_item_sk = rs.cs_item_sk
GROUP BY 
    ci.c_customer_sk, ci.cd_gender, ci.cd_marital_status, ps.total_net_profit, ps.max_discount
HAVING 
    COALESCE(SUM(rs.cs_quantity), 0) > 10
ORDER BY 
    ps.total_net_profit DESC, ci.cd_marital_status ASC;
