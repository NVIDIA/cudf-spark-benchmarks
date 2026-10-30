
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        COUNT(*) AS total_items,
        SUM(rs.ws_net_paid) AS total_revenue
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    s.ws_order_number,
    s.total_items,
    s.total_revenue,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesSummary s
LEFT JOIN 
    CustomerDemographics cd ON s.total_items > 10
WHERE 
    s.total_revenue > 1000
    OR EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = s.ws_order_number
        AND sr.sr_return_quantity > 0
    )
ORDER BY 
    s.total_revenue DESC
LIMIT 100;
