WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END AS adjusted_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
    AVG(fc.adjusted_acctbal) AS avg_supplier_acctbal
FROM 
    RankedOrders o
JOIN 
    lineitem lo ON o.o_orderkey = lo.l_orderkey
JOIN 
    partsupp ps ON lo.l_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fc ON ps.ps_suppkey = fc.s_suppkey
JOIN 
    supplier s ON fc.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND lo.l_shipdate >= '1997-01-01'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY 
    n.n_name, r.r_name;