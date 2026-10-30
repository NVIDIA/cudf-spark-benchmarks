WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
SupplierCosts AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
),
PartStatistics AS (
    SELECT 
        p.p_name AS part_name,
        AVG(p.p_retailprice) AS avg_price,
        MAX(p.p_retailprice) AS max_price
    FROM 
        part p
    GROUP BY 
        p.p_name
)
SELECT 
    r.nation_name,
    r.total_sales,
    s.supplier_name,
    s.total_cost,
    p.part_name,
    p.avg_price,
    p.max_price
FROM 
    RegionalSales r
JOIN 
    SupplierCosts s ON r.nation_name = 'USA'
JOIN 
    PartStatistics p ON p.avg_price < 100.00 
ORDER BY 
    r.total_sales DESC, s.total_cost ASC, p.avg_price DESC
LIMIT 10;