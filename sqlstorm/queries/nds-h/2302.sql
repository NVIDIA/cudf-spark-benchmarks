WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
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
CustomerSegment AS (
    SELECT 
        c.c_nationkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY 
        c.c_nationkey, c.c_mktsegment
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(cs.order_count, 0) AS total_orders,
    rs.order_rank,
    ss.total_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerSegment cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedOrders rs ON rs.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 100))
WHERE 
    r.r_name LIKE 'Africa%'
ORDER BY 
    total_orders DESC NULLS LAST, 
    ss.total_cost DESC;