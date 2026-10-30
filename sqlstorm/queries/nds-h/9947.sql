WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    rp.p_name AS part_name,
    ts.s_name AS supplier_name,
    rp.p_retailprice,
    rp.supplier_count,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON ts.rank <= 5
JOIN 
    nation n ON n.n_nationkey = ts.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    partsupp ps ON ps.ps_partkey = rp.p_partkey AND ps.ps_suppkey = ts.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = rp.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    rp.p_retailprice > 100.00
GROUP BY 
    r.r_name, n.n_name, rp.p_name, ts.s_name, rp.p_retailprice, rp.supplier_count
ORDER BY 
    total_revenue DESC, r.r_name, n.n_name, rp.p_name;
