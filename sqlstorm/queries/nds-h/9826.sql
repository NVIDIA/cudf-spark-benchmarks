
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighlightedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_mfgr,
        ps.ps_availqty,
        s.s_suppkey,
        s.s_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        (p.p_retailprice < 100 OR p.p_size > 50) AND
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice, 
    r.c_name,
    sp.s_name AS supplier_name,
    hp.p_name AS part_name,
    hp.p_retailprice,
    rp.total_supply_cost
FROM 
    RankedOrders r
JOIN 
    HighlightedParts hp ON hp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 50 ORDER BY ps.ps_availqty DESC LIMIT 1)
JOIN 
    SupplierPartSummary sp ON hp.s_suppkey = sp.s_suppkey
LEFT JOIN 
    SupplierPartSummary rp ON rp.total_supply_cost > 5000
WHERE 
    r.order_rank = 1
ORDER BY 
    r.o_totalprice DESC;
