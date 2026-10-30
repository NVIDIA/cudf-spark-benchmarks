
WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
SupplierPartReceived AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    r.region_name,
    r.total_sales AS sales,
    s.s_suppkey,
    s.total_supply_cost,
    spr.total_available,
    spr.distinct_parts
FROM 
    TopRegions r
JOIN 
    TopSuppliers s ON s.total_supply_cost < (SELECT AVG(total_supply_cost) FROM TopSuppliers)
JOIN 
    SupplierPartReceived spr ON s.s_suppkey = spr.s_suppkey
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC, 
    s.total_supply_cost ASC;
