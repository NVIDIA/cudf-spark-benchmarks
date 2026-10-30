WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
        OR p.p_name LIKE '%Aluminum%'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        COUNT(ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    ts.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON ts.parts_count >= 5
JOIN 
    CustomerOrders cs ON cs.total_spent > 5000
WHERE 
    rp.price_rank <= 10
ORDER BY 
    rp.p_retailprice DESC, cs.total_spent DESC;
