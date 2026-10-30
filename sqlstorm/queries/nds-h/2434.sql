WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
OrderSummary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name,
    COALESCE(ps.total_suppliers, 0) AS total_suppliers,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    rp.p_name,
    rp.p_retailprice
FROM 
    nation n
LEFT JOIN 
    SupplierStats ps ON n.n_nationkey = ps.s_nationkey
FULL OUTER JOIN 
    OrderSummary os ON n.n_nationkey = os.c_nationkey
JOIN 
    RankedParts rp ON rp.rn <= 5 AND rp.p_retailprice > 100
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Asia%')
ORDER BY 
    total_order_value DESC, 
    total_suppliers ASC, 
    rp.p_retailprice DESC;
