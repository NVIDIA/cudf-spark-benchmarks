WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(ro.total_revenue), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey AND ro.rn = 1
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
), FilteredSuppliers AS (
    SELECT 
        sp.s_suppkey,
        COUNT(sp.p_partkey) AS parts_count,
        AVG(sp.total_supply_cost) AS avg_supply_cost
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierParts)
    GROUP BY 
        sp.s_suppkey
)
SELECT 
    hvc.c_name,
    hvc.total_spent,
    fs.parts_count,
    fs.avg_supply_cost
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    FilteredSuppliers fs ON hvc.c_custkey = fs.s_suppkey
WHERE 
    hvc.total_spent > 10000 AND (fs.parts_count IS NOT NULL OR fs.avg_supply_cost IS NOT NULL)
ORDER BY 
    hvc.total_spent DESC, fs.avg_supply_cost ASC;
