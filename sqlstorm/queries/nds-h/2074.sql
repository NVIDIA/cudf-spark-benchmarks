
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(lp.l_extendedprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    s.s_name AS supplier_name,
    s.s_acctbal,
    n.n_name AS nation_name,
    RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(lp.l_extendedprice) DESC) AS revenue_rank
FROM 
    part p
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON lp.l_suppkey = s.s_suppkey AND s.rank = 1
JOIN 
    supplier ps ON lp.l_suppkey = ps.s_suppkey
JOIN 
    nation n ON ps.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
WHERE 
    p.p_retailprice > 0 AND 
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, s.s_acctbal, n.n_name, n.n_regionkey
HAVING 
    SUM(lp.l_extendedprice) > 10000
ORDER BY 
    total_revenue DESC, order_count ASC;
