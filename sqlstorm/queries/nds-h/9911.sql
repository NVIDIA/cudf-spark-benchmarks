WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name, r.r_name
),
TopNations AS (
    SELECT 
        nation_name, 
        region_name, 
        total_sales 
    FROM 
        RegionalSales
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    t.nation_name, 
    t.region_name, 
    t.total_sales,
    p.p_name,
    p.p_retailprice
FROM 
    TopNations t
JOIN 
    partsupp ps ON ps.ps_supplycost IN (
        SELECT 
            SUM(l.l_quantity) 
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
        GROUP BY 
            l.l_partkey
    )
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    t.total_sales > 100000
ORDER BY 
    t.total_sales DESC, p.p_retailprice ASC;
