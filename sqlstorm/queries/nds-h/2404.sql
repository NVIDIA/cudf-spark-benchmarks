WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_A.s_acctbal) FROM supplier s_A)
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(tp.s_name, 'Not Available') AS supplier_name,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierParts ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    TopSuppliers tp ON tp.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    nation n ON n.n_nationkey = tp.s_nationkey
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    (li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' OR li.l_shipdate IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_retailprice, tp.s_name, r.r_name
HAVING 
    SUM(li.l_quantity) > 1000 AND MIN(tp.supplier_rank) <= 5
ORDER BY 
    total_revenue DESC, p.p_name;