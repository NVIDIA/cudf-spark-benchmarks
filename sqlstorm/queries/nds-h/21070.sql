WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey
)
SELECT 
    c.c_name,
    COALESCE(cr.total_revenue, 0) AS customer_revenue,
    COALESCE(ss.supply_count, 0) AS supplier_count,
    COALESCE(ss.total_supply_value, 0) AS supplier_value,
    r.r_name AS region_name
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerRevenue cr ON c.c_custkey = cr.c_custkey
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = ps.ps_partkey 
        AND l.l_orderkey IN (
            SELECT ro.o_orderkey 
            FROM RankedOrders ro 
            WHERE ro.rn = 1 AND ro.o_orderstatus = 'F'
        )
    )
    LIMIT 1
)
WHERE c.c_mktsegment IN ('BUILDING', 'AUTO', 'FURNITURE')
AND r.r_name NOT LIKE '%East%'
ORDER BY customer_revenue DESC, supplier_value DESC;
