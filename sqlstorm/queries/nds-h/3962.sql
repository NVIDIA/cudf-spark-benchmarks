WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey = (SELECT n.n_nationkey 
                             FROM nation n 
                             WHERE n.n_name = 'GERMANY')) AS german_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    SUM(CASE 
            WHEN l.l_returnflag = 'Y' THEN l.l_quantity 
            ELSE 0 
        END) AS returns_quantity
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierStats s_stats ON p.p_partkey = s_stats.ps_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = s_stats.ps_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                       FROM part p2) 
    AND l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '1 month'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    net_revenue DESC
LIMIT 10;