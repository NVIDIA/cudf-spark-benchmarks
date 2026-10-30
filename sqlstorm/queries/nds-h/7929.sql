WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
),
SuppByRegion AS (
    SELECT 
        n.n_regionkey,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
),
TotalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rp.p_brand,
    rp.p_type,
    SUM(rp.total_availqty) AS total_available_quantity,
    tr.total_revenue,
    sr.total_acctbal
FROM 
    RankedParts rp
JOIN 
    TotalOrders tr ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IN (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 GROUP BY ps2.ps_partkey))
JOIN 
    SuppByRegion sr ON sr.n_regionkey IN (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'ASIA')
GROUP BY 
    rp.p_brand, rp.p_type, tr.total_revenue, sr.total_acctbal
ORDER BY 
    total_available_quantity DESC, total_revenue DESC;