WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        (CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown Balance'
            WHEN c.c_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Positive Balance' 
         END) AS balance_status
    FROM 
        customer c
    WHERE 
        c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE') 
    AND 
        c.c_acctbal IS NOT NULL
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    rc.c_name,
    rs.s_name,
    rc.balance_status,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS effective_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (SELECT COUNT(*) FROM lineitem WHERE l_discount > 0.2) AS high_discount_count,
    RANK() OVER (ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM 
    FilteredCustomers rc
JOIN 
    RecentOrders o ON rc.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
WHERE 
    rs.rank <= 3
GROUP BY 
    rc.c_name, rs.s_name, rc.balance_status
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY 
    revenue_rank
LIMIT 50
OFFSET 10;