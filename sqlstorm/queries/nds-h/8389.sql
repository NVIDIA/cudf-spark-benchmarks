WITH RegionalSupplierSales AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
        AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        r.r_name, s.s_name
),
TopSuppliers AS (
    SELECT 
        region_name,
        supplier_name,
        total_supply_cost,
        total_orders,
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RegionalSupplierSales
)
SELECT 
    region_name,
    supplier_name,
    total_supply_cost,
    total_orders
FROM 
    TopSuppliers
WHERE 
    rank <= 5
ORDER BY 
    region_name, total_supply_cost DESC;