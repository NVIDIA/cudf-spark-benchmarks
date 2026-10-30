WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_name
),
PartSuppliers AS (
    SELECT 
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_name
)
SELECT 
    rs.region,
    rs.total_sales,
    ps.p_name,
    ps.supply_cost
FROM 
    RegionalSales rs
JOIN 
    PartSuppliers ps ON ps.supply_cost > (SELECT AVG(supply_cost) FROM PartSuppliers)
ORDER BY 
    rs.total_sales DESC, ps.supply_cost ASC;
