WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COUNT(l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_quantity > 10 THEN l.l_quantity END) AS avg_large_quantity,
    MAX(r.order_rank) AS max_order_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedOrders r ON l.l_orderkey = r.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN NationSuppliers ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN HighValueParts hvp ON hvp.ps_partkey = p.p_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2) 
AND s.s_acctbal IS NOT NULL 
AND l.l_shipdate >= '1997-01-01' 
GROUP BY p.p_name, p.p_brand, p.p_container, n.n_name
HAVING COUNT(l.l_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 100;