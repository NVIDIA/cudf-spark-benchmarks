WITH RegionalSales AS (
    SELECT 
        n.n_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    r.region_name,
    r.total_sales,
    r.order_count,
    COALESCE(s.total_available, 0) AS total_available,
    t.s_name AS top_supplier,
    t.total_supply_cost
FROM 
    RegionalSales r
LEFT JOIN 
    SupplierAvailability s ON r.region_name = s.p_name
LEFT JOIN 
    TopSuppliers t ON t.total_supply_cost = (
        SELECT MAX(total_supply_cost) FROM TopSuppliers
    )
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
ORDER BY 
    r.total_sales DESC, r.order_count ASC;
