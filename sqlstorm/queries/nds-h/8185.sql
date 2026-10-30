WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.s_name AS supplier_name,
    ss.total_availqty,
    ss.avg_supplycost,
    ns.total_sales
FROM 
    RankedParts rp
JOIN 
    SupplierStats ss ON rp.p_partkey = ss.s_nationkey
JOIN 
    NationSales ns ON ss.s_nationkey = ns.n_nationkey
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, ns.total_sales DESC;
