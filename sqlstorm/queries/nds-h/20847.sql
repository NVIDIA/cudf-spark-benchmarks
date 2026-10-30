WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
SuppDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
        o.o_orderstatus
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
)
SELECT 
    rc.c_name,
    rc.c_acctbal,
    COALESCE(o.line_count, 0) AS order_line_count,
    COALESCE(o.total_revenue, 0) AS order_total_revenue,
    CASE 
        WHEN rc.rnk = 1 THEN 'Best Customer'
        WHEN rc.rnk <= 5 THEN 'Top Tier'
        ELSE 'Regular'
    END AS customer_tier,
    sd.total_cost AS supplier_total_cost,
    r_name,
    CASE 
        WHEN o.o_orderstatus IS NULL THEN 'No Orders'
        WHEN o.total_revenue > 10000 THEN 'High Value Order'
        ELSE 'Standard Order'
    END AS order_quality
FROM 
    RankedCustomers rc
LEFT JOIN 
    RecentOrders o ON rc.c_custkey = o.o_custkey
LEFT JOIN 
    region r ON rc.c_custkey % 5 = r.r_regionkey 
LEFT JOIN 
    SuppDetails sd ON rc.c_custkey = sd.s_suppkey OR sd.total_cost IS NULL
WHERE 
    rc.rnk < 6
ORDER BY 
    rc.c_acctbal DESC, o.total_revenue DESC NULLS LAST
LIMIT 100
OFFSET 0;