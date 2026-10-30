WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
), CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), LineItemStatistics AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_custkey,
    cs.total_orders,
    cs.total_spent,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank,
    l.net_revenue,
    l.avg_quantity,
    l.returned_items,
    sp.supplied_parts,
    sp.total_supplycost,
    r.r_name AS region_name
FROM CustomerSummary cs
JOIN SupplierPartDetails sp ON cs.c_custkey = sp.s_suppkey 
JOIN LineItemStatistics l ON cs.total_orders = l.l_orderkey
LEFT JOIN nation n ON cs.c_custkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE cs.total_orders > 5 AND sp.total_supplycost IS NOT NULL
ORDER BY cs.total_spent DESC, r.r_name;