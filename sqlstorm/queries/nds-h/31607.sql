
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighRollingSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sp.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_supply_cost > (
            SELECT 
                AVG(total_supply_cost) FROM SupplierParts
        )
)
SELECT 
    cs.c_name,
    cs.total_sales,
    COALESCE(hs.s_name, 'No Supplied Parts') AS top_supplier,
    hs.total_supply_cost
FROM 
    SalesCTE cs
LEFT JOIN 
    HighRollingSuppliers hs ON cs.c_custkey = hs.s_suppkey
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC;
