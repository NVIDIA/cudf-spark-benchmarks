
WITH RecentReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    GROUP BY 
        sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionalSales AS (
    SELECT 
        ws_items.ws_bill_customer_sk,
        SUM(ws_items.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_items.ws_order_number) AS num_orders
    FROM 
        web_sales ws_items
    INNER JOIN 
        promotion p ON ws_items.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws_items.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.cd_marital_status,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ps.total_spent, 0) AS total_spent,
        ps.num_orders AS num_orders,
        CASE 
            WHEN rr.return_count > 5 THEN 'Frequent Returner' 
            ELSE 'Occasional Returner' 
        END AS return_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RecentReturns rr ON cd.c_customer_sk = rr.sr_customer_sk
    LEFT JOIN 
        PromotionalSales ps ON cd.c_customer_sk = ps.ws_bill_customer_sk
)
SELECT 
    *,
    RANK() OVER (PARTITION BY return_category ORDER BY total_spent DESC) AS spending_rank
FROM 
    FinalReport
WHERE 
    total_spent > 1000 OR total_returned > 0
ORDER BY 
    return_category, spending_rank;
