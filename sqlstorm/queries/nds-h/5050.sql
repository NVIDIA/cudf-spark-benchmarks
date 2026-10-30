WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sp.total_supply_cost, 
        sp.part_count,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.s_suppkey
), CustomerOrders AS (
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
), RankedCustomers AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.total_spent, 
        RANK() OVER (ORDER BY co.total_spent DESC) AS rnk
    FROM 
        CustomerOrders co
)

SELECT 
    ts.s_suppkey AS supplier_id,
    ts.s_name AS supplier_name,
    ts.total_supply_cost AS supplier_total_cost,
    rc.c_custkey AS customer_id,
    rc.c_name AS customer_name,
    rc.total_spent AS customer_total_spent
FROM 
    TopSuppliers ts
JOIN 
    RankedCustomers rc ON ts.rnk <= 5 AND rc.rnk <= 5
ORDER BY 
    ts.total_supply_cost DESC, rc.total_spent DESC;
