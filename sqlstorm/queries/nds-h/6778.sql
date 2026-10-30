WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_available,
        sp.total_supply_cost,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS rank
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.total_available > 1000
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
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        ts.s_name AS supplier_name,
        ts.total_available,
        ts.total_supply_cost,
        co.total_spent
    FROM 
        TopSuppliers ts
    JOIN 
        CustomerOrders co ON co.total_spent >= 10000
)
SELECT 
    fr.supplier_name,
    fr.total_available,
    fr.total_supply_cost,
    fr.total_spent
FROM 
    FinalReport fr
ORDER BY 
    fr.total_supply_cost DESC, 
    fr.total_spent DESC
LIMIT 10;
