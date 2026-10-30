
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice < 100.00
),
SupplierPart AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_phone, 
        ps.ps_supplycost, 
        pp.p_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts pp ON ps.ps_partkey = pp.p_partkey
    WHERE 
        pp.rn <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    co.c_name AS customer_name,
    co.total_spent,
    COALESCE(SUM(co.total_spent), 0) AS total_spent_sum
FROM 
    SupplierPart sp
JOIN 
    CustomerOrders co ON sp.p_name LIKE '%' || COALESCE(SUBSTRING(CAST(co.total_spent AS STRING), 1, 3), '') || '%'
GROUP BY 
    sp.s_name, sp.p_name, co.c_name, co.total_spent
ORDER BY 
    total_spent_sum DESC
LIMIT 10;
