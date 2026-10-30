
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank,
        p.p_retailprice
    FROM 
        part p
),
SupplierAndParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        rp.p_partkey, 
        rp.p_name,
        rp.p_retailprice
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        rp.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
)
SELECT 
    cp.c_custkey,
    cp.c_name,
    sp.s_name,
    sp.p_name,
    sp.p_retailprice,
    co.total_spent
FROM 
    CustomerOrders co
JOIN 
    SupplierAndParts sp ON co.o_orderkey = MOD(sp.p_partkey, (SELECT COUNT(*) FROM SupplierAndParts))
JOIN 
    customer cp ON co.c_custkey = cp.c_custkey
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC, cp.c_name ASC;
