WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE 'Widget%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    sp.s_name AS supplier_name,
    sp.part_count,
    sp.total_supply_cost
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 5
JOIN 
    SupplierParts sp ON sp.part_count > 3
WHERE 
    rp.price_rank <= 10
ORDER BY 
    co.total_spent DESC, rp.p_retailprice ASC;
