WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 10000
    ORDER BY 
        s.s_acctbal DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rp.total_available_qty, 
    rp.avg_supply_cost, 
    ts.region_name, 
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey % 5 = ts.s_suppkey % 5
JOIN 
    CustomerOrders co ON co.total_spent > 50000
WHERE 
    rp.total_available_qty > 100
ORDER BY 
    rp.avg_supply_cost DESC, 
    co.total_spent DESC;
