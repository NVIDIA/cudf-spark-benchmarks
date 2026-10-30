WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
FilteredSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.s_address,
        sd.s_phone,
        sd.total_parts,
        sd.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sd.total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_parts > 10
        AND sd.s_address LIKE '%Street%'
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    fs.s_name AS supplier_name,
    fs.total_parts,
    fs.total_supply_cost,
    cod.c_name AS customer_name,
    cod.total_orders,
    cod.total_spent,
    cod.avg_order_value
FROM 
    FilteredSuppliers fs
JOIN 
    CustomerOrderDetails cod ON fs.total_parts = cod.total_orders
WHERE 
    fs.rank <= 5
ORDER BY 
    fs.total_supply_cost DESC, 
    cod.total_spent DESC;
