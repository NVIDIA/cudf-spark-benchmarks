WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-12-01' AND DATE '1997-09-30'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    c.total_spent,
    COALESCE(o.order_rank, 0) AS order_rank,
    l.net_revenue,
    l.distinct_parts,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders' 
        ELSE CASE 
            WHEN c.total_spent > 10000 THEN 'High Roller' 
            WHEN c.total_spent BETWEEN 5000 AND 10000 THEN 'Mid Tier' 
            ELSE 'Budget' 
        END 
    END AS customer_segment
FROM 
    CustomerOrderSummary c
LEFT JOIN 
    RankedOrders o ON c.order_count = o.order_rank
LEFT JOIN 
    LineItemDetails l ON o.o_orderkey = l.l_orderkey
WHERE 
    c.total_spent IS NOT NULL OR l.net_revenue IS NOT NULL
ORDER BY 
    c.total_spent DESC, l.net_revenue DESC;