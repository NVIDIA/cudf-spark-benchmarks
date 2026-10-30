
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > 5000
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
)

SELECT 
    t.c_name AS top_customer,
    rp.p_name AS top_part,
    rp.p_brand AS brand,
    rp.p_retailprice AS price,
    COUNT(sp.ps_partkey) AS available_suppliers
FROM 
    TopCustomers t
JOIN 
    RankedParts rp ON rp.brand_rank = 1
LEFT JOIN 
    SupplierParts sp ON rp.p_partkey = sp.ps_partkey
GROUP BY 
    t.c_name, rp.p_name, rp.p_brand, rp.p_retailprice
ORDER BY 
    available_suppliers DESC, t.c_name;
