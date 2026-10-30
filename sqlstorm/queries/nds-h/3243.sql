
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierTotal AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    ns.n_name AS supplier_nation,
    c.c_name AS customer_name,
    COALESCE(cos.total_orders, 0) AS total_orders,
    COALESCE(cos.total_spent, 0) AS total_spent,
    rp.price_rank,
    st.total_cost
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    CustomerOrderStats cos ON s.s_suppkey = cos.c_custkey 
LEFT JOIN 
    customer c ON cos.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierTotal st ON rp.p_partkey = st.ps_partkey
WHERE 
    rp.price_rank <= 10
    AND (cos.total_orders IS NULL OR cos.total_orders > 5)
ORDER BY 
    rp.p_retailprice DESC, 
    total_spent DESC;
